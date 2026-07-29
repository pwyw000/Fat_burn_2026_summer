#!/bin/bash
# Shared GitHub SSH env for fatburn scripts.
# Fixes Cursor Agent / some Mac networks failing with:
#   ssh: connect to host ssh.github.com port 443: Protocol not available
# Prefer github.com:22 with dedicated key; ignore broken Host rewrites.

KEY="${HOME}/.ssh/id_ed25519_fatburn"
if [[ ! -f "${KEY}" ]]; then
  echo "ERROR: missing SSH key ${KEY}" >&2
  return 1 2>/dev/null || exit 1
fi

# -F /dev/null ignores ~/.ssh/config Host aliases that rewrite to ssh.github.com:443
export GIT_SSH_COMMAND="/usr/bin/ssh -F /dev/null -o BatchMode=yes -o ConnectTimeout=20 -o ServerAliveInterval=15 -o ServerAliveCountMax=2 -o StrictHostKeyChecking=accept-new -o HostName=github.com -p 22 -i ${KEY} -o IdentitiesOnly=yes -o AddressFamily=inet"
export GIT_TERMINAL_PROMPT=0
