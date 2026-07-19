# 把工作区放到 iCloud Drive（手机可搜）

目标路径（Mac）：

```text
~/Library/Mobile Documents/com~apple~CloudDocs/Fat_burn_2026_summer
```

iPhone「文件」App 里显示为：

```text
iCloud 云盘 → Fat_burn_2026_summer → logs → Withings / Garmin / Whoop / meals / training
```

## 在 Mac 上挪一次（Terminal）

先关掉 Cursor / 任何打开该文件夹的窗口，然后执行：

```bash
SRC="${HOME}/Fat_burn_2026_summer"
DST="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Fat_burn_2026_summer"

# 1) 移进 iCloud Drive（整仓移动，保留 .git）
mv "${SRC}" "${DST}"

# 2) 可选：在家目录留一个快捷方式，旧路径习惯仍可用
ln -s "${DST}" "${SRC}"

# 3) 更新 LaunchAgent 用的脚本副本（脚本放在 Application Support，避免云盘权限问题）
mkdir -p "${HOME}/Library/Application Support/fatburn"
cp "${DST}/scripts/auto-commit-push-logs.sh" \
  "${HOME}/Library/Application Support/fatburn/auto-commit-push-logs.sh"
chmod +x "${HOME}/Library/Application Support/fatburn/auto-commit-push-logs.sh"

# 4) 重装 LaunchAgent（若用仓库里的 plist）
cp "${DST}/scripts/com.fatburn.autopush.plist" \
  "${HOME}/Library/LaunchAgents/com.fatburn.autopush.plist"
launchctl unload "${HOME}/Library/LaunchAgents/com.fatburn.autopush.plist" 2>/dev/null || true
launchctl load "${HOME}/Library/LaunchAgents/com.fatburn.autopush.plist"
```

在 Finder 打开 iCloud 里的文件夹确认截图在：

`Fat_burn_2026_summer/logs/...`

并确保文件状态是已下载（不是仅云端小云朵），LaunchAgent 才能读到。

## iPhone 保存截图

1. 截屏 → 分享 → **存储到“文件”**
2. **iCloud 云盘** → **Fat_burn_2026_summer** → **logs** → 选 `Withings` / `Garmin` / `Whoop` / `meals` / `training`
3. 找不到就搜：`Fat_burn_2026_summer`

## 注意

- Git 仓库放在 iCloud 偶发会同步冲突；若 `git` 异常，先等 iCloud 同步完再操作，或暂时关掉该文件夹的优化存储。
- 早晨 autopush 脚本路径仍建议用：`~/Library/Application Support/fatburn/auto-commit-push-logs.sh`（脚本在本地；仓库在 iCloud）。
