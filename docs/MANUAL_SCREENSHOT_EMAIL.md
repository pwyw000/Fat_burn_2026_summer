# 手动上传截图 + 发邮件（Cloud Agent 份额用尽时）

当 Cursor **Cloud Agents 额度用完**、早晨 Automation 跑不了时，用本流程：你上传截图 →（本机或本地 Agent）写计划 → `npm run send-email` 发信。

目标收件人：`pwyw000@gmail.com`。

---

## 一句话流程

```
截图进 logs/ → git push → 写 logs/plans/美东今日.md → npm run send-email
```

---

## 0. 一次性准备（本机只做一次）

在仓库根目录（Google Drive 工作区或本机 clone）：

```bash
cd ~/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My\ Drive/Cursor/Fat_burn_2026_summer
# 或：cd ~/path/to/fat_burn_2026_summer

cp .env.example .env
# 编辑 .env：填入 GMAIL_USER 与 GMAIL_APP_PASSWORD（16 位应用专用密码）
# https://myaccount.google.com/apppasswords

npm install
```

`.env` 示例：

```bash
GMAIL_USER=pwyw000@gmail.com
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx
EMAIL_TO=pwyw000@gmail.com
```

**不要把 `.env` 提交到 Git。**

---

## 1. 手动上传截图

### 路径（区分大小写）

| 文件夹 | 放什么 |
|---|---|
| `logs/Withings/` | 体重 / 体脂 |
| `logs/Whoop/` | 恢复 / 睡眠 |
| `logs/Garmin/` | 有氧 / 跑步 |
| `logs/meals/` | Muscle Booster **Nutrition** 日汇总（不要食物照片） |
| `logs/training/` | 阻力完成页 |

### 推荐方式（手机）

1. iPhone 截屏（保留默认文件名 `Screenshot YYYY-MM-DD at H.MM.SS AM|PM.png`）
2. **Google Drive App** → `Cursor` → `Fat_burn_2026_summer` → 对应 `logs/...`
3. 等 Mac 同步；若已装 LaunchAgent（07:55 自动 push），到点会自动提交；也可立刻手动 push：

```bash
~/Library/Application\ Support/fatburn/auto-commit-push-logs.sh
# 或在仓库里：
git add logs/
git commit -m "chore: add screenshots for $(TZ=America/New_York date +%F)"
git push
```

---

## 2. 写当日计划（邮件正文）

发信脚本默认读取：

`logs/plans/YYYY-MM-DD.md`（`YYYY-MM-DD` = **美东今天**）

### 选项 A：本机 Cursor（不占 Cloud Agent 额度）

在 Cursor Desktop 打开本仓库，把 `docs/DAILY_EMAIL_AUTOMATION.md` 贴给本地 Agent，要求：

1. 读今日截图  
2. 更新 `logs/daily_log.csv`  
3. 写出 `logs/plans/美东今日.md`  
4. **不要**依赖 Cloud Agent；写完后你自己跑发信命令  

### 选项 B：自己写 / 复制昨天改

复制最近一天计划改数字：

```bash
TODAY=$(TZ=America/New_York date +%F)
cp logs/plans/2026-07-23.md "logs/plans/${TODAY}.md"
# 编辑该文件：更新「今日已读截图」、主旋钮、饮食清单
```

计划必须含：截至昨日效果 → 今日已读截图 → 主旋钮（只一个）→ 可执行饮食 → 训练 → 风险 → 明日一句。  
详细规则见 `docs/DAILY_EMAIL_AUTOMATION.md`。

---

## 3. 手动发邮件（核心）

在仓库根目录、已配置 `.env`：

```bash
# 先看会发什么（不真正发送）
npm run send-email:dry

# 确认无误后发送
npm run send-email
```

指定文件 / 标题：

```bash
# 指定计划文件
node scripts/send-fat-loss-email.mjs --file logs/plans/2026-07-24.md

# 或用环境变量
EMAIL_BODY_FILE=logs/plans/2026-07-24.md \
EMAIL_SUBJECT="减脂计划 · 2026-07-24（手动补发）" \
npm run send-email
```

成功时终端会出现：`Sent: <message-id> → pwyw000@gmail.com`。

---

## 4. 发完后建议

```bash
git add logs/daily_log.csv logs/plans/
git commit -m "chore: plan + CSV for $(TZ=America/New_York date +%F) (manual)"
git push
```

这样额度恢复后，Automation 仍有完整历史。

---

## 常见问题

| 问题 | 处理 |
|---|---|
| `Missing GMAIL_USER or GMAIL_APP_PASSWORD` | 检查 `.env` 是否在仓库根；密码为 Google **应用专用密码**，不是登录密码 |
| `No email body found` | 美东今日的 `logs/plans/YYYY-MM-DD.md` 不存在；用 `--file` 指定，或先写计划 |
| dry-run 正常但收不到信 | 查垃圾箱；确认 `EMAIL_TO`；Gmail 是否拦截「不够安全的应用」（应用专用密码一般可过） |
| 截图在 Drive 但 git 里没有 | 跑 `auto-commit-push-logs.sh`，或手动 `git add logs/ && commit && push` |
| Cloud 额度恢复后 | 可重新启用 Automation；手动流程仍可作备份 |

---

## 与自动流程对照

| 步骤 | 自动（Cloud Agent） | 手动（本方案） |
|---|---|---|
| 上传截图 | 你上传 + 本机 07:55 push | **同左**（你必须 push） |
| 读图 / 写 CSV / 写计划 | Automation 08:00 | 本机 Cursor 或手写 `logs/plans/` |
| 发信 | Agent 调同一脚本 | **你**跑 `npm run send-email` |

发信脚本始终是：`scripts/send-fat-loss-email.mjs`（与云端相同）。
