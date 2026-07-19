#!/bin/bash
# Run on the Mac after moving the repo into Google Drive.
# Usage: bash scripts/verify-gdrive-workspace.sh

set -u

GDRIVE_ROOT="${HOME}/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive/Cursor/Fat_burn_2026_summer"
LOCAL_LINK="${HOME}/Fat_burn_2026_summer"
SCRIPT_COPY="${HOME}/Library/Application Support/fatburn/auto-commit-push-logs.sh"
PLIST="${HOME}/Library/LaunchAgents/com.fatburn.autopush.plist"
GIT="/usr/bin/git"
ok=0
fail=0

pass() { echo "OK  $*"; ok=$((ok + 1)); }
warn() { echo "WARN $*"; }
bad()  { echo "FAIL $*"; fail=$((fail + 1)); }

echo "=== Fat Burn Google Drive workspace check ==="
echo

if [[ -d "${GDRIVE_ROOT}/.git" ]]; then
  pass "git repo at Google Drive path"
  ROOT="${GDRIVE_ROOT}"
elif [[ -d "${LOCAL_LINK}/.git" ]]; then
  warn "Google Drive path missing; using ${LOCAL_LINK}"
  ROOT="${LOCAL_LINK}"
else
  bad "no git repo at Google Drive path or ~/Fat_burn_2026_summer"
  ROOT=""
fi

if [[ -L "${LOCAL_LINK}" ]]; then
  pass "symlink ~/Fat_burn_2026_summer -> $(readlink "${LOCAL_LINK}")"
elif [[ -d "${LOCAL_LINK}" ]]; then
  warn "~/Fat_burn_2026_summer exists but is not a symlink"
else
  warn "no ~/Fat_burn_2026_summer shortcut (optional)"
fi

if [[ -n "${ROOT}" ]]; then
  if "${GIT}" -C "${ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    pass "git -C can read repo (LaunchAgent-style access)"
    echo "    branch: $("${GIT}" -C "${ROOT}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
    echo "    head:   $("${GIT}" -C "${ROOT}" rev-parse --short HEAD 2>/dev/null || echo '?')"
  else
    bad "git -C cannot read repo — likely TCC / Drive not mirrored"
  fi

  for d in Withings Garmin Whoop meals training; do
    p="${ROOT}/logs/${d}"
    if [[ -d "${p}" ]]; then
      n=$(find "${p}" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.heic' \) 2>/dev/null | wc -l | tr -d ' ')
      pass "logs/${d}/ exists (${n} images)"
    else
      bad "missing logs/${d}/"
    fi
  done
fi

if [[ -x "${SCRIPT_COPY}" ]]; then
  pass "autopush script copy at Application Support"
else
  bad "missing executable ${SCRIPT_COPY}"
  echo "    fix: mkdir -p \"${HOME}/Library/Application Support/fatburn\" && cp \"${GDRIVE_ROOT}/scripts/auto-commit-push-logs.sh\" \"${SCRIPT_COPY}\" && chmod +x \"${SCRIPT_COPY}\""
fi

if [[ -f "${PLIST}" ]]; then
  pass "LaunchAgent plist installed"
  if launchctl list 2>/dev/null | grep -q 'com.fatburn.autopush'; then
    pass "LaunchAgent loaded (com.fatburn.autopush)"
  else
    warn "LaunchAgent not loaded — run: launchctl load \"${PLIST}\""
  fi
else
  bad "LaunchAgent plist missing at ${PLIST}"
fi

echo
echo "=== summary: ${ok} ok, ${fail} fail ==="
if [[ "${fail}" -gt 0 ]]; then
  echo "If git -C failed: System Settings → Privacy & Security → Full Disk Access → enable /bin/bash"
  echo "Also open the folder once in Finder so Drive downloads files."
  exit 1
fi
echo "Next: run a manual push smoke test:"
echo "  bash \"${SCRIPT_COPY}\""
echo "  tail -n 40 \"${HOME}/Library/Logs/fatburn-autopush.log\""
exit 0
