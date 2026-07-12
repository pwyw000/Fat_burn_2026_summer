# Logs — 只上传截图

你**只需要**把截图丢进对应文件夹。  
`daily_log.csv` / `weekly_review.csv` 由每日早晨的 Agent **根据截图自动维护**，不必手填。

## 文件夹

| 文件夹 | 放什么 |
|---|---|
| `withings/` | 体重、BMI、体脂% 截图 |
| `garmin/` | 有氧/活动截图 |
| `whoop/` | 恢复、睡眠、压力截图 |
| `meals/` | 饮食、外卖、营养标签截图 |
| `training/` | Muscle Booster / 阻力训练截图 |
| `plans/` | 每日计划正文（Agent 自动写入） |

命名建议：`YYYY-MM-DD` 或 `YYYY-MM-DD-描述.png`（例如 `2026-07-12-morning.png`）。

## Agent 自动维护的 CSV

| 文件 | 谁写 | 用途 |
|---|---|---|
| `daily_log.csv` | Agent 每日从截图提取 | 体重/BMI/体脂、训练、恢复、蛋白粗判、备注 |
| `weekly_review.csv` | Agent 每周日汇总 | 周均值、情况码 A–F、下周改动 |

若某天某类截图缺失，CSV 对应字段留空，并在当日邮件里标明「缺 XXX 截图」。
