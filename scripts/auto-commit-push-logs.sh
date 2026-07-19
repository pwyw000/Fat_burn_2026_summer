#!/bin/bash
# Commit + push screenshots/plans/CSV from Google Drive workspace.
# Workspace:
#   ~/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive/Cursor/Fat_burn_2026_summer
# Keep a copy of THIS script at:
#   ~/Library/Application Support/fatburn/auto-commit-push-logs.sh

set -euo pipefail
cd "${HOME}" || true

GDRIVE_ROOT="${HOME}/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive/Cursor/Fat_burn_2026_summer"
LOCAL_FALLBACK="${HOME}/Fat_burn_2026_summer"
ICLOUD_FALLBACK="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Fat_burn_2026_summer"

resolve_root() {
  local candidate
  for candidate in "${GDRIVE_ROOT}" "${LOCAL_FALLBACK}" "${ICLOUD_FALLBACK}"; do
    # Resolve symlink (home shortcut) without requiring cwd inside Drive
    if [[ -L "${candidate}" ]]; then
      candidate="$(readlink "${candidate}" 2>/dev/null || true)"
    fi
    if [[ -n "${candidate}" && -d "${candidate}/.git" ]]; then
      printf '%s' "${candidate}"
      return 0
    fi
  done
  return 1
}

ROOT="$(resolve_root || true)"
if [[ -z "${ROOT}" ]]; then
  ROOT="${GDRIVE_ROOT}"
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
  echo "Move the workspace into Google Drive (see docs/GOOGLE_DRIVE_WORKSPACE.md)."
  exit 1
fi

# Probe Drive readability without cd'ing into the cloud path (TCC-safe).
if ! "${GIT}" -C "${ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: cannot read git repo via git -C (macOS TCC or Drive offline?)."
  echo "Grant Full Disk Access to /bin/bash, open the folder in Finder once, retry."
  exit 1
fi

# Nudge Google Drive to materialize logs if placeholders are online-only.
 /usr/bin/find "${ROOT}/logs" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print -quit >/dev/null 2>&1 || true

"${GIT}" -C "${ROOT}" fetch origin 2>/dev/null || true
"${GIT}" -C "${ROOT}" checkout main 2>/dev/null || true
"${GIT}" -C "${ROOT}" pull --ff-only origin main 2>/dev/null || true

if ! "${GIT}" -C "${ROOT}" add -- \
  "logs/Withings" "logs/Garmin" "logs/Whoop" "logs/meals" "logs/training" "logs/plans" \
  "logs/daily_log.csv" "logs/weekly_review.csv"
then
  echo "ERROR: git add failed — Drive path may be blocked or files not downloaded."
  exit 1
fi

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
