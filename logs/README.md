# Logs — 只上传截图

本机工作区：`~/Fat_burn_2026_summer`（**不用 Google Drive**）。  
你**只负责**把截图放进对应文件夹。CSV 与每日计划由早晨 Agent 自动维护。

## 文件夹（名称请保持一致，区分大小写）

| 文件夹 | 放什么 |
|---|---|
| `Withings/` | 体重、BMI、体脂% |
| `Garmin/` | 有氧 / 跑步 / 活动（请用这个大写 G 目录） |
| `Whoop/` | 恢复、睡眠 |
| `meals/` | **Muscle Booster → Nutrition 标签页** 当日汇总截图（**不再上传食物照片**） |
| `training/` | 阻力训练 |
| `plans/` | Agent 生成的每日计划 |

### `meals/` 上传说明（Muscle Booster Nutrition）

1. 在 Muscle Booster App 打开 **Nutrition** 标签页。  
2. 确保屏幕显示**当日（或昨日）合计**：总热量 kcal、蛋白 / 碳水 / 脂肪 g（能看到的都截进去）。  
3. 每晚睡前或次日早晨上传一张截图到 `logs/meals/`。  
4. 命名：优先保留 iPhone 默认 **`Screenshot YYYY-MM-DD at H.MM.SS AM|PM.png`**。  
Agent **按文件名日期时间**归入日志日，不以 App 画面里的日期标签覆盖文件名。

Agent 从该截图写入 `daily_log.csv` 的 `nutrition_*` 字段，并在邮件里对照目标（蛋白 160–180 g、热量按训练日档位）点评饮食好坏。

## Agent 自动维护

| 文件 | 用途 |
|---|---|
| `daily_log.csv` | 从截图提取的每日数据 |
| `weekly_review.csv` | 周日汇总 + 情况码 A–F |
