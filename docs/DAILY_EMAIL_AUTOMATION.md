# 每日早晨 Automation 指令（存档）

你只上传截图；本 Agent 负责 CSV + 计划 + 邮件。

## 流程（每次触发必须按序完成）

1. **读档案与规则**  
   `docs/PROFILE.md`、`docs/WEEK1_PLAN.md`、`docs/ADJUSTMENT_RULES.md`，以及既有 `logs/daily_log.csv`、`logs/weekly_review.csv`、`logs/plans/` 近期计划。

2. **扫描截图（用户唯一输入）**  
   查看 `logs/withings/`、`logs/garmin/`、`logs/whoop/`、`logs/meals/`、`logs/training/` 中相对上次运行的新文件与最近约 7 天文件。阅读图片内容，提取数字与事实。

3. **维护 CSV（用户不手改）**  
   - 按美东日期更新/追加 `logs/daily_log.csv`：体重、BMI、体脂、阻力是否完成、有氧是否完成与分钟、WHOOP 备注、蛋白是否大致达标、notes。  
   - 截图读不清的字段留空，不要编造。  
   - 若今天是周日（美东）：按调整规则汇总本周，写入/更新 `logs/weekly_review.csv`（含 case_code A–F 与 next_week_change）。  
   - 将 CSV 与当日计划文件的变更提交并推送到当前分支（便于下次继续）。

4. **检索网络减脂建议**  
   用可信来源补充「维持瘦体重、温和缺口、蛋白、恢复」等要点，必须按个人截图与规则裁剪，禁止照搬通用极端节食。

5. **生成当日计划**  
   写入 `logs/plans/YYYY-MM-DD.md`（美东日期），结构：  
   数据摘要 → 今日主旋钮（只改一个）→ 饮食要点 → 训练建议 → 风险 → 明日一句行动。  
   原则：维持 BMI / 降体脂%；一次一个主旋钮；WHOOP 差先减练（情况 F）。

6. **发信**  
   `npm install`（如需要）后执行发信脚本，收件人 `pwyw000@gmail.com`。  
   环境变量：`GMAIL_USER`、`GMAIL_APP_PASSWORD`（可选 `EMAIL_TO`）。  
   先确保计划文件已写好，再发送该文件内容。

## 缺数据时

缺某类截图：CSV 留空 + 邮件标明缺什么 + 仍给出可执行的保守建议（优先执行与恢复，不猛加缺口）。
