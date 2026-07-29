# GitHub 推送故障排查与一键同步

## 症状

Cursor Agent（或偶发本地）执行 `git push` 失败：

```text
ssh: connect to host ssh.github.com port 443: Protocol not available
fatal: Could not read from remote repository.
```

本地 commit 成功，但 **remote 仍落后**（`git status` 显示 `ahead of 'origin/main' by N`）。

## 根因（已复现）

1. 本机曾把 `~/.ssh/config` 里的 `Host github.com` **改写到** `ssh.github.com:443`（当时 port 22 不稳定）。
2. **Cursor Agent 沙箱 / 部分网络路径** 连 `ssh.github.com:443` 会报 `Protocol not available`。
3. 同一台 Mac 上，**直连 `github.com:22`** 或 **显式 `-p 443 -o HostName=ssh.github.com`** 往往正常；HTTPS 到 `github.com` 也正常。
4. Agent 里的 `GIT_SSH_COMMAND` 若仍走默认 Host 改写，就会踩中上述失败。

## 已落地修复

### 1. `~/.ssh/config`（本机）

- `Host github.com` → **`github.com:22`** + `id_ed25519_fatburn`
- 保留备用别名 **`github.com-443`** → `ssh.github.com:443`（仅 port 22 被墙时用）

备份：`~/.ssh/config.bak.fatburn.*`

### 2. 仓库脚本

| 文件 | 作用 |
|---|---|
| `scripts/git-ssh-env.sh` | 统一 `GIT_SSH_COMMAND`：`-F /dev/null` + `github.com:22` + fatburn key |
| `scripts/auto-commit-push-logs.sh` | LaunchAgent 07:55 用；已 source 上面的 SSH env |
| `scripts/sync-and-mail.sh` | **一键**：推截图（可加 docs）+ 可选发邮件；SSH 失败则试 :443，再试 HTTPS token |
| `scripts/Sync Fat Burn.command` | Finder 双击 → `--all`（docs + logs + 今日邮件） |

### 3. HTTPS 备用（可选）

在 `.env` 增加（**勿提交**）：

```bash
GITHUB_TOKEN=ghp_xxxxxxxx   # classic PAT，勾选 repo
```

`sync-and-mail.sh` 在 SSH 全失败时会用该 token 推 `main`。

## 一键用法（推荐）

在 **本机 Terminal**（不要指望 Agent 沙箱里 push）执行：

```bash
REPO="$HOME/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive/Cursor/Fat_burn_2026_summer"

# 仅推截图 / plans / CSV（与 07:55 相同）
bash "$REPO/scripts/sync-and-mail.sh"

# 推日志 + 文档/脚本 + 发今日邮件
bash "$REPO/scripts/sync-and-mail.sh" --all

# 只发邮件（计划已写好、无需再推）
bash "$REPO/scripts/sync-and-mail.sh" --email --push-only
```

或 Finder 双击：`scripts/Sync Fat Burn.command`（首次可能要右键 → 打开）。

安装到 Application Support（与 LaunchAgent 一致）：

```bash
REPO="$HOME/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive/Cursor/Fat_burn_2026_summer"
mkdir -p "$HOME/Library/Application Support/fatburn"
cp "$REPO/scripts/"{auto-commit-push-logs,git-ssh-env,sync-and-mail}.sh \
  "$HOME/Library/Application Support/fatburn/"
chmod +x "$HOME/Library/Application Support/fatburn/"*.sh \
  "$REPO/scripts/Sync Fat Burn.command"
```

日志：`~/Library/Logs/fatburn-sync-and-mail.log` · `~/Library/Logs/fatburn-autopush.log`

## Agent 工作流约定

1. Agent **生成** `logs/plans/YYYY-MM-DD.md`、更新 CSV、**本机发邮件可以**（读 `.env` + nodemailer）。
2. Agent **不要依赖** 沙箱内 `git push`；完成后让你跑一句：
   ```bash
   bash ".../scripts/sync-and-mail.sh" --all
   ```
   或你说「一键上传」时 Agent 应调用该脚本并请求 **本机权限**（`all`），而不是裸 `git push`。
3. 日常截图仍可走 LaunchAgent **07:55** autopush。

## 手动自检

```bash
# 应看到: Hi pwyw000! You've successfully authenticated...
ssh -T git@github.com

# 仓库是否领先 remote
git -C "$REPO" status -sb

# 强制用脚本里的 SSH 探测
source "$REPO/scripts/git-ssh-env.sh"
git -C "$REPO" ls-remote origin HEAD
```

若仍失败：换网络 / 关 VPN 试一次；或设置 `GITHUB_TOKEN` 走 HTTPS。

## 相关历史

- 专用 key：`~/.ssh/id_ed25519_fatburn`（autopush 用）
- 曾用 443 改写规避 port 22；现 port 22 可用，改写反而触发 Agent 的 `Protocol not available`
- Google Drive mmap / TCC 问题见 `docs/GOOGLE_DRIVE_WORKSPACE.md`
