#!/bin/bash
# Auto-commit and push screenshots + plans + CSV before the 08:00 cloud email job.
# Runs via LaunchAgent ~07:45. Script lives OUTSIDE Google Drive to avoid TCC blocks.

set -euo pipefail

ROOT="/Users/kejiawu/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive/Cursor/Fat_burn_2026_summer"
RUN_LOG="${HOME}/Library/Logs/fatburn-autopush.log"
GIT="/usr/bin/git"
DATE_ET="$(TZ=America/New_York /bin/date '+%Y-%m-%d')"
TS="$(TZ=America/New_York /bin/date '+%Y-%m-%d %H:%M:%S %Z')"

mkdir -p "${HOME}/Library/Logs"
exec >>"${RUN_LOG}" 2>&1
echo "---- ${TS} start ----"

export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -i ${HOME}/.ssh/id_ed25519_fatburn -o IdentitiesOnly=yes"

# Use git -C so we never need getcwd on the Drive path as CWD
if ! "${GIT}" -C "${ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: cannot access git repo at ${ROOT}"
  echo "macOS may be blocking LaunchAgent from Google Drive. Grant Full Disk Access to /bin/bash in System Settings → Privacy & Security."
  exit 1
fi

"${GIT}" -C "${ROOT}" add \
  -- "logs/Withings" "logs/Garmin" "logs/Whoop" "logs/meals" "logs/training" "logs/plans" \
  "logs/daily_log.csv" "logs/weekly_review.csv" \
  || true

if "${GIT}" -C "${ROOT}" diff --cached --quiet; then
  echo "Nothing to commit."
  echo "---- ${TS} done (no-op) ----"
  exit 0
fi

MSG="chore: sync screenshots, plans, and CSV for ${DATE_ET}"
"${GIT}" -C "${ROOT}" commit -m "${MSG}"

if ! "${GIT}" -C "${ROOT}" push origin HEAD; then
  echo "ERROR: git push failed."
  exit 1
fi

echo "Pushed: ${MSG}"
echo "---- ${TS} done ----"
