# 每日计划 Agent 指令（手动触发）

你上传截图后 **手动触发** 本 Agent；Agent 负责 CSV + Slow Carb 饮食计划 + 训练安排 + 邮件。  
**不依赖定时 Automation**；何时发信由你决定。

## 一键触发口令（Cursor 聊天）

| 你说 | 执行 |
|---|---|
| **今日计划** | 读截图 → CSV → `logs/plans/今天.md` |
| **今日计划并发邮件** | 同上 + Gmail 发信 |
| **今日计划 + 上传** | 同上 + `scripts/sync-and-mail.sh` 推 GitHub |

> `npm run send-email` **不会**生成计划；若缺少 `logs/plans/YYYY-MM-DD.md` 会报错。先说「今日计划」再发信。

详见 `.cursor/rules/daily-plan.mdc`。

## 截图目录（必须用这些精确路径，区分大小写）

云端 Linux **区分大小写**。仓库里实际目录是：

| 路径 | 内容 |
|---|---|
| `logs/Withings/` | 体重 / BMI / 体脂 |
| `logs/Garmin/` | 有氧、跑步、活动（**不是** `logs/garmin/`） |
| `logs/Whoop/` | 恢复 / 睡眠 |
| `logs/meals/` | **Muscle Booster → Nutrition 标签页** 当日汇总截图（**不要上传食物照片**） |
| `logs/training/` | 阻力训练 |

扫描时：`ls`/`find` 这些精确路径；把目录下**所有图片**都打开阅读。

## 截图日期规则（硬性 · iPhone 文件名优先）

文件名格式：`Screenshot YYYY-MM-DD at H.MM.SS AM|PM.png`

1. 从文件名解析 `YYYY-MM-DD` 与时间 → **正式时间戳**。  
2. 数字归入**文件名日期**对应的美东日志日。  
3. App 内「Jul 13」等仅作备注；**不得**把文件名日期=今天的 Withings 改判成别日。  
4. 同日多张：取文件名时间**最晚**的一张作主数据。  
5. 邮件每张今日图须写：`文件名 → 解析时间 → 读到的数字`。

## 流程（每次手动触发按序完成）

1. **读规则**  
   `docs/PROFILE.md`、`docs/WEEK1_PLAN.md`、`docs/ADJUSTMENT_RULES.md`，以及 CSV 与 `logs/plans/` 近期计划。

2. **扫描截图**  
   阅读五个目录新文件与近 7 天文件。  
   - **Garmin：** 类型、时长、距离、配速、心率、卡路里 → notes。  
   - **`logs/meals/`：** kcal、蛋白/碳水/脂肪 g → CSV。  
   - **Withings：** 文件名日期=今天 → 必须写入今日 CSV 与邮件。

3. **维护 CSV**  
   - upsert `logs/daily_log.csv`（美东日期）。  
   - Garmin 有活动 → `cardio_done=yes`，`cardio_minutes` 填分钟。  
   - Nutrition → `nutrition_kcal`、`nutrition_protein_g`、`nutrition_carbs_g`、`nutrition_fat_g`。  
   - `protein_ok`：≥ **160 g** → `yes`；否则 `no`；无截图留空。  
   - 周日：写 `logs/weekly_review.csv`（对照 **−1% 体重/周** 目标）。  
   - 提交并推送 CSV + 计划（若用户要求 commit）。

4. **检索网络减脂建议**（可信来源），按个人数据裁剪；禁止极端节食。

5. **生成当日计划** → `logs/plans/YYYY-MM-DD.md`  
   硬目标：**每周约 −1% 体重（脂肪为主）**；体重 **≥ 160 lb**；**Slow Carb + 周六 Cheat**；**2 跑 4 力 1 休**。

6. **发信**（用户触发时）到 `pwyw000@gmail.com`（`GMAIL_USER` / `GMAIL_APP_PASSWORD`）。

## 固定周训练（邮件须对照写「今日练什么」）

| 日 | 训练 |
|---|---|
| 周日 | **跑步** |
| 周一 | **力量** |
| 周二 | **力量** |
| 周三 | **跑步** |
| 周四 | **力量** |
| 周五 | **力量** |
| 周六 | **休息 + Cheat Day** |

## 能量与饮食（邮件必写）

- 引用 **BMR ≈ 1,740 · 周赤字÷6 ≈ 1,020 kcal/Slow Carb 日 · 周六 Cheat 不计赤字**（见 `WEEK1_PLAN.md` 分档）。  
- **Slow Carb 食谱：直接套用 `WEEK1_PLAN.md` §3.1（力量日 ~1,600 kcal）或 §3.2（跑日 ~2,000 kcal）**；禁止空泛建议。  
- 昨日 Nutrition 有缺口 → 在清单开头写一行 **「昨日差 X g 蛋白 / Y kcal → 今日加码：…」**，并对照 §3.3 加码表。  
- **周六 Cheat Day**：邮件写放开说明 + **周日回归 §3.1 清单**。  
- 每一餐表格须含：**购物/装盘 · 用量 · 约 kcal · 约蛋白 · 调味**。

### 训练日热量分档

| 日类型 | 套用模板 | 目标 kcal |
|---|---|---:|
| 纯休 Slow Carb 日 | §3.1 略减豆 50 g/餐 | 1,400–1,550 |
| 力量日（Mon/Tue/Thu/Fri） | **§3.1** | 1,550–1,700 |
| 跑步日（Sun/Wed） | **§3.2** | 2,000–2,150 |
| Cheat Day（周六） | 不设清单上限 · **不计赤字** | — |

---

## 邮件正文模板（Agent 必须按此结构输出）

```markdown
# 减脂计划 · YYYY-MM-DD（星期 · [力量日/跑步日/Cheat日] · Slow Carb）

硬目标：每周约 **−1% 体重（脂肪为主）**；体重 **≥160 lb**；**Slow Carb**（周六 Cheat · 周赤字÷6）。

## 1. 截至昨日（M/D）减脂效果

**效果总览：** [开局 → 昨日 → 今晨 Withings；一句趋势]

| 环节 | 好 / 不好 | 依据 |
|---|---|---|
| **饮食** | | Nutrition 昨日 kcal / 蛋白 vs 分档 |
| **运动（有氧）** | | Garmin 周日/周三跑 |
| **锻炼（阻力）** | | training 本周次数 |

**今日主旋钮（只一个）：** [一句]

## 2. 能量预算（当前体重 W lb）

| 项目 | 数值 |
|---|---|
| BMR | ~XXX kcal |
| 周赤字 | W×1%×3500 = XXX kcal |
| Slow Carb 日赤字 | XXX ÷ 6 = XXX kcal |
| **今日目标** | **XXX–XXX kcal · 蛋白 165–175 g** |

## 3. 数据摘要

### 今日已读截图（按文件名解析时间）
[表格：文件名 → 时间 → 数字]

### 昨日 Nutrition（若有）
[表格 + 一行缺口点评]

### 今日仍缺
[缺什么截图]

## 4. 今日 Slow Carb 清单（[§3.1 力量日 ~1,600 / §3.2 跑日 ~2,000]）

> 昨日蛋白差 **X g** / 热量差 **Y kcal** → 今日加码：[§3.3 条目]

### 早餐 · ~XXX kcal · ~XX g 蛋白
[表格：购物/装盘 | 用量 | kcal | 蛋白 | 调味]

### 午餐 · ~XXX kcal · ~XX g 蛋白
[表格]

### [跑后 · 仅跑日] · ~XXX kcal · ~XX g 蛋白
[表格]

### 晚餐 · ~XXX kcal · ~XX g 蛋白
[表格]

### 加餐 · ~XXX kcal · ~XX g 蛋白
[表格]

**全日合计：~XXXX kcal · ~XXX g 蛋白**

## 5. 训练

| 项目 | 今日 |
|---|---|
| 有氧 | [跑 / 不跑] |
| 阻力 | [Muscle Booster 侧重] |
| 恢复 | [Whoop 颜色 + 睡眠] |

## 6. 风险

- [体重地板 / 连续低热量 / Cheat spillover / 缺口执行]

## 7. 明日一句

[一句可执行行动]
```

### 饮食段落硬性规则

1. **力量日**：默认复制 `WEEK1_PLAN.md` **§3.1** 四餐表，可轮换鸡胸/三文鱼/虾。  
2. **跑步日**：默认复制 **§3.2**（含跑后香蕉+粉）。  
3. **周六**：不写 kcal 上限；写「Cheat 放开 + 周日早餐起恢复 §3.1」。  
4. **周日（Cheat 次日）**：用 §3.1，备注「不因晨重 spike 砍热量」。  
5. 表格**必须**有 kcal 与蛋白 g；**禁止**只写「多吃蛋白」「多加豆类」而不给克数。

## 截至昨日减脂效果（邮件第 1 项，必写）

| 环节 | 看什么 |
|---|---|
| **饮食** | Nutrition：蛋白 ≥160 g？kcal 是否落在 Slow Carb 分档？Cheat 是否 spillover？ |
| **有氧** | Garmin：周日/周三跑是否完成？ |
| **阻力** | training：本周是否朝 **4×/周** 推进？ |

- 先一句**效果总览**（相对开局或上周；缺数据写明缺什么）。  
- 各一句：**哪好哪差**；最后一句 **今日主旋钮**（只一个）。

## Muscle Booster Nutrition（`logs/meals/`）

只上传 App **Nutrition 标签页** 日汇总。读失败则邮件说明，仍给保守 Slow Carb 清单。

## 缺数据

缺某类截图：CSV 留空 + 邮件标明 + 仍给可执行建议。  
Garmin 有文件却读失败：必须写明文件名与原因。
