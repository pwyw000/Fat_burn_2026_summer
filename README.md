# Fat Burn 2026 Summer

两月减脂追踪 + **每日早晨邮件计划**。你只需把截图丢进 `logs/Withings|Garmin|Whoop|meals|training`；CSV 与当日计划由定时 Agent 自动维护，并邮件推送到 `pwyw000@gmail.com`。

**硬目标：** 约 2 个月体脂 → **12%**；体重 **不得低于 160 lb**。

## 快速开始

1. 截图放进对应文件夹（见 [logs/README.md](logs/README.md)）——**不用手改 CSV**；`meals/` 只放 **Muscle Booster Nutrition 标签页** 截图（不上传食物照片）
2. 阅读 [docs/WEEK1_PLAN.md](docs/WEEK1_PLAN.md)（含每餐克数模板）与 [docs/ADJUSTMENT_RULES.md](docs/ADJUSTMENT_RULES.md)
3. Cursor Automation：**美东每天 08:00**（cron `0 8 * * *`）
4. 本机 LaunchAgent：**每天 07:45** 自动 push **截图 + `logs/plans/` + CSV**（不含文档/脚本）。脚本在本机：`scripts/auto-commit-push-logs.sh`

## 本地试发邮件

1. 在 [Google 账号安全设置](https://myaccount.google.com/apppasswords) 生成 **应用专用密码**（需已开两步验证）
2. 复制 `.env.example` → `.env`，填入 `GMAIL_USER` 与 `GMAIL_APP_PASSWORD`
3. 写一份计划到 `logs/plans/YYYY-MM-DD.md`（日期用美东当天）
4. 安装并发送：

```bash
npm install
npm run send-email:dry
npm run send-email
```

Cloud Agent 需在 [Cloud Agents 设置](https://cursor.com/dashboard?tab=cloud-agents) 配置同名密钥：`GMAIL_USER`、`GMAIL_APP_PASSWORD`（可选 `EMAIL_TO`）。

## 目录

| 路径 | 作用 |
|---|---|
| `logs/withings|garmin|whoop|meals|training/` | 分类截图（`meals/` = Muscle Booster Nutrition 汇总） |
| `logs/plans/` | 每日生成的计划正文 |
| `scripts/send-fat-loss-email.mjs` | Gmail 发信 |
| `docs/` | 档案、基线计划、调整规则 |
