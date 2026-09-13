#!/usr/bin/env bash
# Materialize Gitea SSH credentials from Cursor Runtime Secrets.
# Never prints secret material. Safe to re-run.
set -euo pipefail

umask 077

: "${GITEA_SSH_PRIVATE_KEY_B64:?GITEA_SSH_PRIVATE_KEY_B64 is required}"
: "${GITEA_SSH_KNOWN_HOSTS:?GITEA_SSH_KNOWN_HOSTS is required}"

GITEA_SSH_HOST="${GITEA_SSH_HOST:-ssh.pika-os.com}"
KEY_PATH="${GITEA_SSH_KEY_PATH:-$HOME/.ssh/id_ed25519_gitea}"
KNOWN_HOSTS_PATH="${GITEA_SSH_KNOWN_HOSTS_PATH:-$HOME/.ssh/known_hosts}"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

printf '%s\n' "$GITEA_SSH_KNOWN_HOSTS" >"$KNOWN_HOSTS_PATH"
chmod 644 "$KNOWN_HOSTS_PATH"

printf '%s' "$GITEA_SSH_PRIVATE_KEY_B64" | base64 -d >"$KEY_PATH"
chmod 600 "$KEY_PATH"

if [[ -n "${GITEA_SSH_PASSPHRASE:-}" ]]; then
  eval "$(ssh-agent -s)" >/dev/null
  SSH_ASKPASS_REQUIRE=force DISPLAY= \
    SSH_ASKPASS="$(mktemp)" \
    bash -c 'printf "%s\n" "#!/bin/sh\necho \"$GITEA_SSH_PASSPHRASE\"" > "$SSH_ASKPASS"; chmod +x "$SSH_ASKPASS"; ssh-add "'"$KEY_PATH"'"'
else
  export GIT_SSH_COMMAND="ssh -i ${KEY_PATH} -o IdentitiesOnly=yes -o UserKnownHostsFile=${KNOWN_HOSTS_PATH}"
fi

# Persist for subsequent shells in the same session when sourced
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  export GIT_SSH_COMMAND
  export GITEA_SSH_KEY_PATH="$KEY_PATH"
  export GITEA_SSH_KNOWN_HOSTS_PATH="$KNOWN_HOSTS_PATH"
fi

# Write an env snippet agents can source without re-decoding (no secrets)
ENV_SNIPPET="${XDG_RUNTIME_DIR:-/tmp}/otter-gitea-ssh.env"
cat >"$ENV_SNIPPET" <<EOF
export GIT_SSH_COMMAND='ssh -i ${KEY_PATH} -o IdentitiesOnly=yes -o UserKnownHostsFile=${KNOWN_HOSTS_PATH}'
export GITEA_SSH_KEY_PATH='${KEY_PATH}'
export GITEA_SSH_KNOWN_HOSTS_PATH='${KNOWN_HOSTS_PATH}'
EOF
chmod 600 "$ENV_SNIPPET"

if [[ "${1:-}" == "--check" ]]; then
  ssh -i "$KEY_PATH" -o IdentitiesOnly=yes -o UserKnownHostsFile="$KNOWN_HOSTS_PATH" \
    -T "git@${GITEA_SSH_HOST}" 2>&1 | head -c 200 || true
  echo
  echo "ok: bootstrap complete (env snippet: $ENV_SNIPPET)"
else
  echo "ok: Gitea SSH ready (source $ENV_SNIPPET or re-export GIT_SSH_COMMAND)"
fi
