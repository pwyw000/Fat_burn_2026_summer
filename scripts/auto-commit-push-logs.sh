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
  # Optional explicit override for non-standard Drive layouts.
  for candidate in "${FATBURN_REPO:-}" "${GDRIVE_ROOT}" "${LOCAL_FALLBACK}" "${ICLOUD_FALLBACK}"; do
    [[ -n "${candidate}" ]] || continue
    # Resolve symlink (home shortcut) without requiring cwd inside Drive
    if [[ -L "${candidate}" ]]; then
      candidate="$(readlink "${candidate}" 2>/dev/null || true)"
    fi
    if [[ -n "${candidate}" && -d "${candidate}/.git" ]]; then
      printf '%s' "${candidate}"
      return 0
    fi
  done

  # The user may have manually moved the folder elsewhere under Google Drive.
  # Discover its real location instead of requiring "My Drive/Cursor".
  if [[ -d "${HOME}/Library/CloudStorage" ]]; then
    while IFS= read -r candidate; do
      if [[ -d "${candidate}/.git" ]]; then
        printf '%s' "${candidate}"
        return 0
      fi
    done < <(
      /usr/bin/find "${HOME}/Library/CloudStorage" \
        -maxdepth 8 -type d -name 'Fat_burn_2026_summer' 2>/dev/null
    )
  fi
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
ACTIVE_PID=""
WATCHDOG_PID=""

mkdir -p "${HOME}/Library/Logs"
# Show progress in Terminal and preserve the same output in the LaunchAgent log.
exec > >(/usr/bin/tee -a "${RUN_LOG}") 2>&1
echo "---- ${TS} start ----"
echo "ROOT=${ROOT}"

export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=20 -o ServerAliveInterval=15 -o ServerAliveCountMax=2 -i ${HOME}/.ssh/id_ed25519_fatburn -o IdentitiesOnly=yes"

cleanup_children() {
  if [[ -n "${WATCHDOG_PID}" ]] && kill -0 "${WATCHDOG_PID}" 2>/dev/null; then
    kill "${WATCHDOG_PID}" 2>/dev/null || true
  fi
  if [[ -n "${ACTIVE_PID}" ]] && kill -0 "${ACTIVE_PID}" 2>/dev/null; then
    kill -TERM "${ACTIVE_PID}" 2>/dev/null || true
  fi
}
trap cleanup_children EXIT
trap 'cleanup_children; exit 130' INT TERM

run_timed() {
  local seconds="$1"
  local label="$2"
  local status
  shift 2

  echo "STEP: ${label} (timeout ${seconds}s)"
  "$@" &
  ACTIVE_PID=$!
  (
    sleep "${seconds}"
    if kill -0 "${ACTIVE_PID}" 2>/dev/null; then
      echo "TIMEOUT: ${label} exceeded ${seconds}s"
      kill -TERM "${ACTIVE_PID}" 2>/dev/null || true
    fi
  ) &
  WATCHDOG_PID=$!

  set +e
  wait "${ACTIVE_PID}"
  status=$?
  set -e

  kill "${WATCHDOG_PID}" 2>/dev/null || true
  wait "${WATCHDOG_PID}" 2>/dev/null || true
  ACTIVE_PID=""
  WATCHDOG_PID=""

  if [[ "${status}" -eq 0 ]]; then
    echo "OK: ${label}"
  else
    echo "FAILED: ${label} (exit ${status})"
  fi
  return "${status}"
}

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

# Google Drive's virtual filesystem (File Stream / FUSE) throws
#   fatal: mmap failed: Resource deadlock avoided
# when `git add` mmaps files to hash them. Stream large blobs instead of
# mmap-ing them, and disable the threaded index preload. This is the root-cause
# fix for the 07:55 autopush failing at the staging step.
"${GIT}" -C "${ROOT}" config core.bigFileThreshold 1 || true
"${GIT}" -C "${ROOT}" config core.preloadindex false || true

if ! run_timed 90 "git fetch origin" \
  "${GIT}" -C "${ROOT}" fetch origin
then
  echo "WARNING: fetch failed; continuing with the local checkout."
fi

if ! run_timed 30 "git checkout main" \
  "${GIT}" -C "${ROOT}" checkout main
then
  echo "ERROR: cannot switch to main; resolve local changes first."
  exit 1
fi

# Normal case: fast-forward. If local main diverged from origin/main (e.g. the
# cloud agent advanced origin/main via merged PRs while this machine committed
# screenshots locally), fall back to a non-editing merge so the histories
# reconcile automatically. Screenshot adds vs. remote CSV/plan edits don't
# overlap, so this merges cleanly; on a real conflict we abort and warn instead
# of leaving the repo mid-merge.
if ! run_timed 90 "git pull --ff-only origin main" \
  "${GIT}" -C "${ROOT}" pull --ff-only origin main
then
  echo "WARNING: ff-only pull failed (diverged); trying a merge."
  if ! run_timed 90 "git pull --no-rebase --no-edit origin main" \
    "${GIT}" -C "${ROOT}" pull --no-rebase --no-edit origin main
  then
    echo "WARNING: merge pull failed; aborting half-merge and continuing."
    "${GIT}" -C "${ROOT}" merge --abort 2>/dev/null || true
  fi
fi

# Force Google Drive to materialize (download) every log file locally BEFORE
# git touches it. A plain streaming read (cat) hydrates cloud placeholders
# without mmap, so the later `git add` operates on local bytes and never hits
# the mmap "Resource deadlock avoided" hydration deadlock.
if ! run_timed 180 "hydrate Drive log files" \
  /bin/bash -c '/usr/bin/find "'"${ROOT}"'/logs" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.csv" -o -iname "*.md" \) -print0 | while IFS= read -r -d "" f; do /bin/cat "$f" > /dev/null 2>&1 || true; done'
then
  echo "WARNING: hydration step had trouble; continuing to staging anyway."
fi

if ! run_timed 180 "stage logs from Google Drive" \
  "${GIT}" -C "${ROOT}" add -- \
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
if ! run_timed 60 "commit logs" \
  "${GIT}" -C "${ROOT}" commit -m "${MSG}"
then
  echo "ERROR: commit failed"
  exit 1
fi

if ! run_timed 120 "push logs to GitHub" \
  "${GIT}" -C "${ROOT}" push origin HEAD
then
  echo "ERROR: push failed"
  exit 1
fi

echo "Pushed: ${MSG}"
echo "---- ${TS} done ----"
