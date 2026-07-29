#!/bin/bash
# One-click: commit + push fat-burn logs (and optional docs) to GitHub,
# optionally send today's plan email.
#
# Usage (from Terminal, or double-click Sync Fat Burn.command):
#   ./scripts/sync-and-mail.sh              # push logs only
#   ./scripts/sync-and-mail.sh --docs       # also commit docs/README
#   ./scripts/sync-and-mail.sh --email      # after push, send today's plan email
#   ./scripts/sync-and-mail.sh --all        # docs + logs + email
#   ./scripts/sync-and-mail.sh --push-only  # push existing commits, no new commit
#
# Install / update local copy:
#   cp scripts/{auto-commit-push-logs,git-ssh-env,sync-and-mail}.sh \
#      ~/Library/Application\ Support/fatburn/
#   chmod +x ~/Library/Application\ Support/fatburn/*.sh

set -euo pipefail

DO_DOCS=0
DO_EMAIL=0
PUSH_ONLY=0
for arg in "$@"; do
  case "${arg}" in
    --docs) DO_DOCS=1 ;;
    --email) DO_EMAIL=1 ;;
    --all) DO_DOCS=1; DO_EMAIL=1 ;;
    --push-only) PUSH_ONLY=1 ;;
    -h|--help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown flag: ${arg}" >&2
      exit 2
      ;;
  esac
done

GDRIVE_ROOT="${HOME}/Library/CloudStorage/GoogleDrive-pwyw000@gmail.com/My Drive/Cursor/Fat_burn_2026_summer"
LOCAL_FALLBACK="${HOME}/Fat_burn_2026_summer"
GIT="/usr/bin/git"
DATE_ET="$(TZ=America/New_York /bin/date '+%Y-%m-%d')"
TS="$(TZ=America/New_York /bin/date '+%Y-%m-%d %H:%M:%S %Z')"
RUN_LOG="${HOME}/Library/Logs/fatburn-sync-and-mail.log"

resolve_root() {
  local candidate
  for candidate in "${FATBURN_REPO:-}" "${GDRIVE_ROOT}" "${LOCAL_FALLBACK}"; do
    [[ -n "${candidate}" ]] || continue
    if [[ -L "${candidate}" ]]; then
      candidate="$(readlink "${candidate}" 2>/dev/null || true)"
    fi
    if [[ -n "${candidate}" && -d "${candidate}/.git" ]]; then
      printf '%s' "${candidate}"
      return 0
    fi
  done
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
if [[ -z "${ROOT}" || ! -d "${ROOT}/.git" ]]; then
  echo "ERROR: cannot find Fat_burn_2026_summer git repo"
  exit 1
fi

mkdir -p "${HOME}/Library/Logs"
exec > >(/usr/bin/tee -a "${RUN_LOG}") 2>&1
echo "==== ${TS} sync-and-mail start ===="
echo "ROOT=${ROOT}"
echo "flags: docs=${DO_DOCS} email=${DO_EMAIL} push_only=${PUSH_ONLY}"

# SSH env (github.com:22, ignore broken Host→443 rewrite)
if [[ -f "${ROOT}/scripts/git-ssh-env.sh" ]]; then
  # shellcheck source=/dev/null
  source "${ROOT}/scripts/git-ssh-env.sh"
elif [[ -f "${HOME}/Library/Application Support/fatburn/git-ssh-env.sh" ]]; then
  # shellcheck source=/dev/null
  source "${HOME}/Library/Application Support/fatburn/git-ssh-env.sh"
fi

push_with_fallback() {
  echo "STEP: git push origin HEAD (SSH :22)"
  if "${GIT}" -C "${ROOT}" push origin HEAD; then
    echo "OK: push via SSH"
    return 0
  fi
  echo "WARNING: SSH push failed; trying SSH :443 fallback"
  export GIT_SSH_COMMAND="/usr/bin/ssh -F /dev/null -o BatchMode=yes -o ConnectTimeout=20 -o StrictHostKeyChecking=accept-new -o HostName=ssh.github.com -p 443 -i ${HOME}/.ssh/id_ed25519_fatburn -o IdentitiesOnly=yes -o AddressFamily=inet"
  if "${GIT}" -C "${ROOT}" push origin HEAD; then
    echo "OK: push via SSH :443"
    return 0
  fi
  echo "WARNING: SSH :443 failed; trying HTTPS + token from .env"
  if [[ -f "${ROOT}/.env" ]]; then
    # shellcheck disable=SC1091
    set -a
    # parse KEY=VAL without executing arbitrary shell
    while IFS= read -r line || [[ -n "${line}" ]]; do
      line="${line%$'\r'}"
      [[ -z "${line}" || "${line}" == \#* ]] && continue
      [[ "${line}" != *=* ]] && continue
      key="${line%%=*}"
      val="${line#*=}"
      key="$(echo "${key}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      val="$(echo "${val}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^["'\'']//;s/["'\'']$//')"
      case "${key}" in
        GITHUB_TOKEN|GH_TOKEN) export GITHUB_TOKEN="${val}" ;;
      esac
    done < "${ROOT}/.env"
    set +a
  fi
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    if "${GIT}" -C "${ROOT}" push \
      "https://x-access-token:${GITHUB_TOKEN}@github.com/pwyw000/Fat_burn_2026_summer.git" \
      HEAD:main
    then
      echo "OK: push via HTTPS token"
      return 0
    fi
  else
    echo "NOTE: set GITHUB_TOKEN in .env for HTTPS fallback (classic PAT with repo scope)."
  fi
  echo "ERROR: all push methods failed — see docs/GITHUB_PUSH.md"
  return 1
}

if [[ "${PUSH_ONLY}" -eq 1 ]]; then
  push_with_fallback
else
  # Reuse autopush for logs (hydrate + stage + commit + push)
  AUTOPUSH="${ROOT}/scripts/auto-commit-push-logs.sh"
  if [[ ! -x "${AUTOPUSH}" ]]; then
    AUTOPUSH="${HOME}/Library/Application Support/fatburn/auto-commit-push-logs.sh"
  fi
  if [[ ! -f "${AUTOPUSH}" ]]; then
    echo "ERROR: auto-commit-push-logs.sh not found"
    exit 1
  fi
  bash "${AUTOPUSH}"

  if [[ "${DO_DOCS}" -eq 1 ]]; then
    echo "STEP: stage docs / README"
    "${GIT}" -C "${ROOT}" config core.bigFileThreshold 1 || true
    "${GIT}" -C "${ROOT}" add -- \
      README.md docs scripts/git-ssh-env.sh scripts/sync-and-mail.sh \
      scripts/auto-commit-push-logs.sh package.json 2>/dev/null || true
    if ! "${GIT}" -C "${ROOT}" diff --cached --quiet; then
      "${GIT}" -C "${ROOT}" commit -m "docs: GitHub push fix + one-click sync (${DATE_ET})"
      push_with_fallback
    else
      echo "Nothing new in docs/scripts to commit."
      # Still push if ahead
      if [[ -n "$("${GIT}" -C "${ROOT}" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)" ]] \
        && [[ "$("${GIT}" -C "${ROOT}" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)" != "0" ]]; then
        push_with_fallback
      fi
    fi
  else
    # If autopush was no-op but we are ahead, push remaining commits
    ahead="$("${GIT}" -C "${ROOT}" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)"
    if [[ "${ahead}" != "0" ]]; then
      echo "Local ahead by ${ahead}; pushing remaining commits."
      push_with_fallback
    fi
  fi
fi

if [[ "${DO_EMAIL}" -eq 1 ]]; then
  PLAN="${ROOT}/logs/plans/${DATE_ET}.md"
  if [[ ! -f "${PLAN}" ]]; then
    echo "ERROR: no plan file ${PLAN} — generate it in Cursor first, then re-run with --email"
    exit 1
  fi
  echo "STEP: send email for ${DATE_ET}"
  NODE_BIN=""
  for candidate in \
    "/Applications/Cursor.app/Contents/Resources/app/resources/helpers/node" \
    "$(command -v node || true)"
  do
    if [[ -n "${candidate}" && -x "${candidate}" ]]; then
      NODE_BIN="${candidate}"
      break
    fi
  done
  if [[ -z "${NODE_BIN}" ]]; then
    echo "ERROR: node not found"
    exit 1
  fi
  # Load .env safely
  if [[ -f "${ROOT}/.env" ]]; then
    while IFS= read -r line || [[ -n "${line}" ]]; do
      line="${line%$'\r'}"
      [[ -z "${line}" || "${line}" == \#* ]] && continue
      [[ "${line}" != *=* ]] && continue
      key="${line%%=*}"
      val="${line#*=}"
      key="$(echo "${key}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      val="$(echo "${val}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^["'\'']//;s/["'\'']$//')"
      case "${key}" in
        GMAIL_USER|GMAIL_APP_PASSWORD|EMAIL_TO|EMAIL_SUBJECT|EMAIL_BODY_FILE)
          export "${key}=${val}"
          ;;
      esac
    done < "${ROOT}/.env"
  fi
  export EMAIL_BODY_FILE="${PLAN}"
  export EMAIL_SUBJECT="${EMAIL_SUBJECT:-减脂计划 · ${DATE_ET}}"
  (cd "${ROOT}" && "${NODE_BIN}" scripts/send-fat-loss-email.mjs)
  echo "OK: email sent"
fi

echo "==== ${TS} sync-and-mail done ===="
echo "Log: ${RUN_LOG}"
