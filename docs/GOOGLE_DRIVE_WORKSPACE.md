# 把工作区放到 Google Drive（手机可存截图）

目标路径（Mac，Google Drive for Desktop）：

```text
~/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive/Cursor/Fat_burn_2026_summer
```

iPhone **Google Drive** App 里：

```text
我的云端硬盘 → Cursor → Fat_burn_2026_summer → logs → Withings / Garmin / Whoop / meals / training
```

> 用 **Google Drive App** 找，不是 iPhone「文件」里的 iCloud。

## Automation 如何读取截图

Cursor Cloud Automation **不能直接读取你 Mac 上挂载的 Google Drive**。Automation 的 Repo 仍应设为 GitHub：

```text
github.com/pwyw000/Fat_burn_2026_summer (main)
```

正确链路：

```text
iPhone → Google Drive → Mac LaunchAgent 07:55 commit/push → GitHub main → Automation 08:00
```

所以不用把 Automation Repo 改成 Google Drive；需要修的是 Mac 上的 autopush 脚本。

## 在 Mac 上挪一次（Terminal）

先关掉 Cursor / 打开该文件夹的窗口，确认 Google Drive 桌面版已登录且 “My Drive” 已镜像，然后：

```bash
SRC="${HOME}/Fat_burn_2026_summer"
# 若你已经挪到 iCloud，改用下一行作 SRC：
# SRC="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Fat_burn_2026_summer"

GDRIVE_ROOT="${HOME}/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive"
DST="${GDRIVE_ROOT}/Cursor/Fat_burn_2026_summer"

mkdir -p "${GDRIVE_ROOT}/Cursor"

# 1) 整仓移进 Google Drive（保留 .git）
mv "${SRC}" "${DST}"

# 2) 可选：家目录快捷方式，旧路径习惯仍可用
ln -sfn "${DST}" "${HOME}/Fat_burn_2026_summer"

# 3) LaunchAgent 脚本放本地 Application Support（减少云盘权限/TCC 问题）
mkdir -p "${HOME}/Library/Application Support/fatburn"
cp "${DST}/scripts/auto-commit-push-logs.sh" \
  "${HOME}/Library/Application Support/fatburn/auto-commit-push-logs.sh"
chmod +x "${HOME}/Library/Application Support/fatburn/auto-commit-push-logs.sh"

# 4) 重装 LaunchAgent
cp "${DST}/scripts/com.fatburn.autopush.plist" \
  "${HOME}/Library/LaunchAgents/com.fatburn.autopush.plist"
launchctl unload "${HOME}/Library/LaunchAgents/com.fatburn.autopush.plist" 2>/dev/null || true
launchctl load "${HOME}/Library/LaunchAgents/com.fatburn.autopush.plist"
```

在 Finder 打开 Google Drive 路径，确认 `logs/` 下截图在，且文件已下载到本机（不是仅云端）。

## iPhone 保存截图

1. 安装并登录同一账号的 **Google Drive** App  
2. 截屏 → 分享 → **Drive** / **保存到 Google Drive**  
   （若没有该选项：分享 → **存储到“文件”** → 浏览里选 **Google Drive**，需已在「文件」里启用 Drive 位置）  
3. 路径：`我的云端硬盘` → `Cursor` → `Fat_burn_2026_summer` → `logs` → 选子文件夹  
4. 搜不到就在 Drive App 顶部搜索：`Fat_burn_2026_summer`

建议把 `logs/Withings` 等子文件夹加星标，下次保存更快。

## 挪好后立刻验证（Mac）

在仓库目录执行（或任意位置用绝对路径）：

```bash
bash "${HOME}/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive/Cursor/Fat_burn_2026_summer/scripts/verify-gdrive-workspace.sh"
```

应看到多项 `OK`。然后装脚本并冒烟推送：

```bash
DST="${HOME}/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive/Cursor/Fat_burn_2026_summer"

mkdir -p "${HOME}/Library/Application Support/fatburn"
cp "${DST}/scripts/auto-commit-push-logs.sh" \
  "${HOME}/Library/Application Support/fatburn/auto-commit-push-logs.sh"
chmod +x "${HOME}/Library/Application Support/fatburn/auto-commit-push-logs.sh"

cp "${DST}/scripts/com.fatburn.autopush.plist" \
  "${HOME}/Library/LaunchAgents/com.fatburn.autopush.plist"
launchctl unload "${HOME}/Library/LaunchAgents/com.fatburn.autopush.plist" 2>/dev/null || true
launchctl load "${HOME}/Library/LaunchAgents/com.fatburn.autopush.plist"

bash "${HOME}/Library/Application Support/fatburn/auto-commit-push-logs.sh"
tail -n 40 "${HOME}/Library/Logs/fatburn-autopush.log"
```

日志里应有 `ROOT=...GoogleDrive.../Fat_burn_2026_summer`，以及 `Pushed:` 或 `Nothing to commit.`

脚本会自动搜索 `~/Library/CloudStorage` 下手动移动后的
`Fat_burn_2026_summer`，不要求一定放在 `My Drive/Cursor`。若想强制指定真实路径：

```bash
FATBURN_REPO="/把 Finder 里的文件夹拖到这里/" \
  bash "${HOME}/Library/Application Support/fatburn/auto-commit-push-logs.sh"
```

## 读取 / LaunchAgent

历史上 Google Drive 曾触发 macOS TCC，LaunchAgent 读不到目录。当前策略：

- **仓库**在 Google Drive（方便手机上传）  
- **autopush 脚本**在 `~/Library/Application Support/fatburn/`（本机）  
- 脚本只用 `git -C`，不把云盘当 cwd  

若验证/`git -C` 失败：

1. 系统设置 → 隐私与安全性 → **完全磁盘访问权限** → 打开 `/bin/bash`  
2. Finder 打开一次 `Fat_burn_2026_summer/logs`，等 Drive 下载完成  
3. 再跑 `verify-gdrive-workspace.sh`  

日志：`~/Library/Logs/fatburn-autopush.log`。

## `git add` 报 `mmap failed: Resource deadlock avoided`

**症状：** 每天 07:55 的 autopush 在日志里走到 `STEP: stage logs from Google Drive` 就失败：

```text
fatal: mmap failed: Resource deadlock avoided
FAILED: stage logs from Google Drive (exit 128)
```

`launchctl list | grep fatburn` 显示任务**有加载**、但上次退出码非 0——说明定时任务在跑，只是每天都卡在 `git add` 这一步（所以截图一直没自动推上 GitHub）。

**原因：** 仓库在 Google Drive（File Stream / FUSE 虚拟盘）。`git add` 会 `mmap` 文件来算哈希，而 Drive 在 mmap 触发按需下载时会返回 `EDEADLK`（资源死锁），大 PNG 尤其容易触发。与认证、网络无关。

**修复（`scripts/auto-commit-push-logs.sh` 已内置，无需手动）：**

1. `git config core.bigFileThreshold 1` —— 让 git 对大文件**流式写入、不走 mmap**。
2. `git config core.preloadindex false` —— 关掉多线程索引预载。
3. `git add` 前先 `cat` 每个 `logs/` 文件到 `/dev/null`，**强制 Drive 先把文件下载到本地**，这样后续 mmap 不再触发下载。

**装新版脚本（把仓库里改好的脚本复制到本机运行位置）：**

```bash
DST="${HOME}/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive/Cursor/Fat_burn_2026_summer"
cp "${DST}/scripts/auto-commit-push-logs.sh" \
  "${HOME}/Library/Application Support/fatburn/auto-commit-push-logs.sh"
chmod +x "${HOME}/Library/Application Support/fatburn/auto-commit-push-logs.sh"

# 立即验证一次
bash "${HOME}/Library/Application Support/fatburn/auto-commit-push-logs.sh"
tail -n 40 "${HOME}/Library/Logs/fatburn-autopush.log"
```

日志里出现 `OK: stage logs from Google Drive` 与 `Pushed:`（或 `Nothing to commit.`）即修复成功。

**兜底（万一仍失败）：** 在 Google Drive App 设置里对 `Cursor/Fat_burn_2026_summer` 选 **“可离线使用 / Available offline”**，让文件常驻本地，从源头避免 mmap 触发下载。

## 本地 main 与 origin/main 分叉（`fatal: Not possible to fast-forward`）

**症状：** autopush 日志里 `git pull --ff-only origin main` 报：

```text
Your branch and 'origin/main' have diverged, and have N and M different commits each
fatal: Not possible to fast-forward, aborting.
```

**原因：** 本机在 `main` 上直接提交截图，而 `origin/main` 是通过云端合并的 PR 前进的，两条历史岔开，无法快进。

**脚本已自愈：** 新版 autopush 在 ff 失败时会自动改用 `git pull --no-rebase --no-edit`（合并）。截图的新增文件与远程的 CSV/计划改动不重叠，通常干净合并；真冲突时会 `merge --abort` 并告警，不会把仓库卡在半合并状态。

**一次性把当前分叉理顺**（先在 GitHub 合并待处理 PR，使 `origin/main` 完整，再执行）：

```bash
REPO="${HOME}/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive/Cursor/Fat_burn_2026_summer"
git -C "$REPO" fetch origin main
git -C "$REPO" checkout main
git -C "$REPO" merge --no-edit origin/main   # 或确认本地无独有内容后：git -C "$REPO" reset --hard origin/main
git -C "$REPO" push origin main
```

之后本地与远程一致，autopush 每天即可正常 ff/合并并推送。
