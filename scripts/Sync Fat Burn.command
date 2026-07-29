#!/bin/bash
# Double-click in Finder (or open from Terminal) to push logs + send today's email.
# Uses the repo next to this file, or the Google Drive workspace.

cd "$(dirname "$0")" || exit 1
ROOT="$(cd .. && pwd)"
if [[ ! -d "${ROOT}/.git" ]]; then
  ROOT="${HOME}/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive/Cursor/Fat_burn_2026_summer"
fi
exec /bin/bash "${ROOT}/scripts/sync-and-mail.sh" --all
