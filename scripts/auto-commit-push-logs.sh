#!/bin/bash
# Commit + push screenshots/plans/CSV from iCloud Drive workspace.
# Workspace: ~/Library/Mobile Documents/com~apple~CloudDocs/Fat_burn_2026_summer
# Keep a copy of THIS script at:
#   ~/Library/Application Support/fatburn/auto-commit-push-logs.sh

set -euo pipefail
cd "${HOME}" || true

ICLOUD_ROOT="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Fat_burn_2026_summer"
# Fallback if user still has the old local SSD path or a symlink
LOCAL_FALLBACK="${HOME}/Fat_burn_2026_summer"

if [[ -d "${ICLOUD_ROOT}/.git" ]]; then
  ROOT="${ICLOUD_ROOT}"
elif [[ -d "${LOCAL_FALLBACK}/.git" ]]; then
  ROOT="${LOCAL_FALLBACK}"
else
  ROOT="${ICLOUD_ROOT}"
fi

RUN_LOG="${HOME}/Library/Logs/fatburn-autopush.log"
GIT="/usr/bin/git"
DATE_ET="$(TZ=America/New_York /bin/date '+%Y-%m-%d')"
TS="$(TZ=America/New_York /bin/date '+%Y-%m-%d %H:%M:%S %Z')"

mkdir -p "${HOME}/Library/Logs"
exec >>"${RUN_LOG}" 2>&1
echo "---- ${TS} start ----"
echo "ROOT=${ROOT}"

export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=20 -i ${HOME}/.ssh/id_ed25519_fatburn -o IdentitiesOnly=yes"

if [[ ! -d "${ROOT}/.git" ]]; then
  echo "ERROR: git repo missing at ${ROOT}"
  echo "Move the workspace into iCloud Drive (see docs/ICLOUD_WORKSPACE.md)."
  exit 1
fi

"${GIT}" -C "${ROOT}" fetch origin 2>/dev/null || true
"${GIT}" -C "${ROOT}" checkout main 2>/dev/null || true
"${GIT}" -C "${ROOT}" pull --ff-only origin main 2>/dev/null || true

"${GIT}" -C "${ROOT}" add -- \
  "logs/Withings" "logs/Garmin" "logs/Whoop" "logs/meals" "logs/training" "logs/plans" \
  "logs/daily_log.csv" "logs/weekly_review.csv" \
  || true

if "${GIT}" -C "${ROOT}" diff --cached --quiet; then
  echo "Nothing to commit."
  UNTRACKED="$("${GIT}" -C "${ROOT}" ls-files --others --exclude-standard -- "logs/" | head -20 || true)"
  if [[ -n "${UNTRACKED}" ]]; then
    echo "WARNING: untracked remain:"
    echo "${UNTRACKED}"
  fi
  echo "---- ${TS} done (no-op) ----"
  exit 0
fi

MSG="chore: sync screenshots, plans, and CSV for ${DATE_ET}"
"${GIT}" -C "${ROOT}" commit -m "${MSG}"

if ! "${GIT}" -C "${ROOT}" push origin HEAD; then
  echo "ERROR: push failed"
  exit 1
fi

echo "Pushed: ${MSG}"
echo "---- ${TS} done ----"
