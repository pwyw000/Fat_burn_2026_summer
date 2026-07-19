#!/bin/bash
# Commit + push screenshots/plans/CSV from local SSD repo.
# Workspace: ~/Fat_burn_2026_summer (not Google Drive).

set -euo pipefail
cd "${HOME}" || true

LOCAL_ROOT="${HOME}/Fat_burn_2026_summer"
RUN_LOG="${HOME}/Library/Logs/fatburn-autopush.log"
GIT="/usr/bin/git"
DATE_ET="$(TZ=America/New_York /bin/date '+%Y-%m-%d')"
TS="$(TZ=America/New_York /bin/date '+%Y-%m-%d %H:%M:%S %Z')"

mkdir -p "${HOME}/Library/Logs"
exec >>"${RUN_LOG}" 2>&1
echo "---- ${TS} start ----"

export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=20 -i ${HOME}/.ssh/id_ed25519_fatburn -o IdentitiesOnly=yes"

if [[ ! -d "${LOCAL_ROOT}/.git" ]]; then
  echo "ERROR: local repo missing: ${LOCAL_ROOT}"
  exit 1
fi

"${GIT}" -C "${LOCAL_ROOT}" fetch origin 2>/dev/null || true
"${GIT}" -C "${LOCAL_ROOT}" checkout main 2>/dev/null || true
"${GIT}" -C "${LOCAL_ROOT}" pull --ff-only origin main 2>/dev/null || true

"${GIT}" -C "${LOCAL_ROOT}" add -- \
  "logs/Withings" "logs/Garmin" "logs/Whoop" "logs/meals" "logs/training" "logs/plans" \
  "logs/daily_log.csv" "logs/weekly_review.csv" \
  || true

if "${GIT}" -C "${LOCAL_ROOT}" diff --cached --quiet; then
  echo "Nothing to commit."
  UNTRACKED="$("${GIT}" -C "${LOCAL_ROOT}" ls-files --others --exclude-standard -- "logs/" | head -20 || true)"
  if [[ -n "${UNTRACKED}" ]]; then
    echo "WARNING: untracked remain:"
    echo "${UNTRACKED}"
  fi
  echo "---- ${TS} done (no-op) ----"
  exit 0
fi

MSG="chore: sync screenshots, plans, and CSV for ${DATE_ET}"
"${GIT}" -C "${LOCAL_ROOT}" commit -m "${MSG}"

if ! "${GIT}" -C "${LOCAL_ROOT}" push origin HEAD; then
  echo "ERROR: push failed"
  exit 1
fi

echo "Pushed: ${MSG}"
echo "---- ${TS} done ----"
