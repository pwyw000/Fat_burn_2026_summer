# 重建每日减脂邮件 Automation

仓库里**没有**仍在跑的 Automations 来源 Agent（`source=automations` 为 0）。按本页可从零重建。

## 目标

| 项 | 值 |
|---|---|
| 名称 | `Daily fat-loss email`（或 `每日减脂计划邮件`） |
| 触发 | Scheduled · 美东每天 **08:00** |
| 仓库 | `pwyw000/fat_burn_2026_summer` · 分支 `main` |
| 权限 | Private（个人计费） |
| 输出 | 更新 CSV/计划并推送 + Gmail 发信到 `pwyw000@gmail.com` |

## 一步步重建

1. 打开 [cursor.com/automations](https://cursor.com/automations) → **New automation**  
   （或本机 Agent 会话用 `/automate`，粘贴下方描述让 Cursor 生成配置后再改。）
2. **Trigger：** Scheduled  
   - 时区选 **America/New_York**（若 UI 有时区）  
   - Cron：`0 8 * * *`（美东 08:00）  
   - 若 cron **固定 UTC**：用 `0 12 * * *`（EDT=UTC−4）或 `0 13 * * *`（EST=UTC−5）
3. **Repository：** 必须选本仓库（不要用 no-repo；Agent 要改 CSV/计划并 push）
4. **Instructions：** 粘贴 [`AUTOMATION_PROMPT.md`](./AUTOMATION_PROMPT.md) 全文  
   详细规则在 [`DAILY_EMAIL_AUTOMATION.md`](./DAILY_EMAIL_AUTOMATION.md)
5. **Tools：** 保持默认即可（需 git push；不必开 Slack）。PR 创建可关——日常应直接 commit/push `main` 上的 logs，不必每次开 PR。
6. **Secrets**（Cloud Agents 环境）：确认已有  
   - `GMAIL_USER` = `pwyw000@gmail.com`  
   - `GMAIL_APP_PASSWORD` = Google 应用专用密码  
   - 可选 `EMAIL_TO` = `pwyw000@gmail.com`  
   设置页：[Cloud Agents](https://cursor.com/dashboard?tab=cloud-agents)
7. **Save → Enable**，点一次 **Run now** 做冒烟测试。

## `/automate` 一句话（本机会话）

```
创建一个 Cursor Automation：仓库 pwyw000/fat_burn_2026_summer，美东每天 08:00（cron 0 8 * * *，时区 America/New_York），严格按 docs/DAILY_EMAIL_AUTOMATION.md 扫描 logs 截图、更新 CSV、写 logs/plans 当日计划、npm run send-email 发到 pwyw000@gmail.com；提示词用 docs/AUTOMATION_PROMPT.md。
```

## 本地对照

本机 LaunchAgent 约 **07:45** 推截图（`scripts/auto-commit-push-logs.sh`），Automation **08:00** 读仓库发信——中间留约 15 分钟缓冲。

## 验证清单

- [ ] Automation 状态 Enabled  
- [ ] 最近一次 run 的 `source` 为 `automations`  
- [ ] `logs/plans/YYYY-MM-DD.md` 已更新并推送  
- [ ] 邮箱收到「减脂计划 · YYYY-MM-DD」  
- [ ] 缺截图时邮件写明缺什么，未编造数字  
