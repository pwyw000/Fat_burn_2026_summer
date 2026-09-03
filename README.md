# Fat Burn 2026 Summer

两月减脂追踪 + **手动触发每日邮件计划**。你把截图丢进 `logs/Withings|Garmin|Whoop|meals|training`，再手动触发 Agent；CSV 与当日计划由 Agent 维护，并可邮件推送到 `pwyw000@gmail.com`。

**硬目标：** 每周约 **−0.5% 体重（以脂肪为主）**；体脂朝 **12%**；体重 **不得低于 160 lb**。

**饮食：** **Slow Carb Diet** · **周六 Cheat Day**  
**训练：** 周日 + 周三 **跑步** · Mon 肩+臂 / Tue 胸+腹 / Thu 背+后束 / Fri 下肢（**20 min 超级组**）· 周六 **休息（Cheat 餐前深蹲）**

**工作区（Google Drive，手机可存）：**  
`~/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive/Cursor/Fat_burn_2026_summer`  
iPhone：**Google Drive App** → 我的云端硬盘 → `Cursor` → `Fat_burn_2026_summer` → `logs/...`  
迁移步骤见 [docs/GOOGLE_DRIVE_WORKSPACE.md](docs/GOOGLE_DRIVE_WORKSPACE.md)。

## 快速开始

1. 截图放进对应文件夹（见 [logs/README.md](logs/README.md)）——**不用手改 CSV**；`meals/` 只放 **Muscle Booster Nutrition 标签页** 截图
2. 阅读 [docs/WEEK1_PLAN.md](docs/WEEK1_PLAN.md)（BMR/TDEE、Slow Carb 食谱、周训练表）与 [docs/ADJUSTMENT_RULES.md](docs/ADJUSTMENT_RULES.md)
## 一键生成今日计划（Cursor Agent）

`npm run send-email` **只发信，不生成计划**。计划必须由 Agent 读截图后写出 `logs/plans/YYYY-MM-DD.md`。

**在 Cursor 聊天里发一句即可：**

| 你说 | Agent 会做 |
|---|---|
| **今日计划** | 读截图 → 写 CSV → 写 `logs/plans/今天.md` |
| **今日计划并发邮件** | 上面 + 发 Gmail |
| **今日计划 + 上传** | 计划 + 推 GitHub |
| **计划上传邮件** | **计划 + 推 GitHub + 发邮件**（推荐） |

规则已写在 `.cursor/rules/daily-plan.mdc`。

**本机只发信（计划已存在时）：**

```bash
npm run send-email
```

**本机推截图 + 发信（不生成计划正文）：**

```bash
npm run sync:all
```

## 能量预算摘要（169.6 lb · 41 岁 · 6'0"）

| 项目 | 数值 |
|---|---|
| BMR | ≈ **1,715 kcal/日** |
| 周目标 | **−0.85 lb/周**（≈ 0.5% 体重） |
| Slow Carb 日赤字 | **÷6 ≈ 495 kcal**（周六 Cheat 不计） |
| Whoop 日常消耗 | **2,100 kcal** |
| 力量日摄入 | ≈ **1,600–1,800 kcal** |
| 跑步日摄入 | ≈ **2,150–2,350 kcal** |

## 本地试发邮件

1. 在 [Google 账号安全设置](https://myaccount.google.com/apppasswords) 生成 **应用专用密码**
2. 复制 `.env.example` → `.env`，填入 `GMAIL_USER` 与 `GMAIL_APP_PASSWORD`
3. 写一份计划到 `logs/plans/YYYY-MM-DD.md`
4. `npm install` → `npm run send-email:dry` → `npm run send-email`

## 目录

| 路径 | 作用 |
|---|---|
| `logs/withings|garmin|whoop|meals|training/` | 分类截图 |
| `logs/plans/` | 每日生成的计划正文 |
| `scripts/send-fat-loss-email.mjs` | Gmail 发信 |
| `scripts/sync-and-mail.sh` | **一键**推截图/文档 + 可选发邮件 |
| `scripts/Sync Fat Burn.command` | Finder 双击入口（`--all`） |
| `docs/GITHUB_PUSH.md` | SSH `Protocol not available` 根因与修复 |
| `docs/` | 档案、Slow Carb 计划、调整规则、[进度复盘 2026-09-03](docs/PROGRESS_REVIEW_2026-09-03.md) |
