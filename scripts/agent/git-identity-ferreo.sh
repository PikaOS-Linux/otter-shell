#!/usr/bin/env bash
# Export ferreo commit identity and neutralize Cursor Co-Authored-By injection.
#
# Cursor Cloud Agents set:
#   user.name=Cursor Agent, user.email=cursoragent@cursor.com
#   commit.gpgsign=true (Cursor HSM SSH signing)
#   core.hooksPath → commit-msg.cursor.co-author (appends Co-authored-by)
#
# Howard convention: author/committer name ferreo, no Cursor trailers/attribution.
# Default email matches recent otter-shell parent commits; override with GITEA_GIT_EMAIL.
set -euo pipefail

NAME="${GITEA_GIT_NAME:-ferreo}"
EMAIL="${GITEA_GIT_EMAIL:-harderthanfire@gmail.com}"

export GIT_AUTHOR_NAME="$NAME"
export GIT_AUTHOR_EMAIL="$EMAIL"
export GIT_COMMITTER_NAME="$NAME"
export GIT_COMMITTER_EMAIL="$EMAIL"

# Avoid Cursor-signed commits on Gitea SoT (signing key is Cursor's, not ferreo's).
export GIT_COMMITTER_GPGSIGN=false
# Older git honors commit.gpgsign via -c; export a helper flag for wrappers.
export OTTER_GIT_NO_CURSOR_SIGN=1

# Disable only the co-author injector; keep secret scanner (commit-msg.cursor).
HOOKS_PATH="$(git config --get core.hooksPath 2>/dev/null || true)"
if [[ -n "$HOOKS_PATH" && -x "$HOOKS_PATH/commit-msg.cursor.co-author" ]]; then
  chmod -x "$HOOKS_PATH/commit-msg.cursor.co-author" || true
  echo "ok: disabled $HOOKS_PATH/commit-msg.cursor.co-author"
fi

ENV_SNIPPET="${XDG_RUNTIME_DIR:-/tmp}/otter-git-identity-ferreo.env"
cat >"$ENV_SNIPPET" <<EOF
export GIT_AUTHOR_NAME='${NAME}'
export GIT_AUTHOR_EMAIL='${EMAIL}'
export GIT_COMMITTER_NAME='${NAME}'
export GIT_COMMITTER_EMAIL='${EMAIL}'
export OTTER_GIT_NO_CURSOR_SIGN=1
EOF
chmod 600 "$ENV_SNIPPET"

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_SNIPPET"
fi

echo "ok: identity ${NAME} <${EMAIL}> (source $ENV_SNIPPET)"
echo "hint: commit with: git -c user.name=${NAME} -c user.email=${EMAIL} -c commit.gpgsign=false commit ..."
echo "hint: or use scripts/agent/commit.sh"
