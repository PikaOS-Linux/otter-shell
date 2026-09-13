#!/usr/bin/env bash
# Thin commit wrapper: ferreo identity, no Cursor co-author, no Cursor signing.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/git-identity-ferreo.sh" >/dev/null
# shellcheck disable=SC1091
source "${XDG_RUNTIME_DIR:-/tmp}/otter-git-identity-ferreo.env"

NAME="${GIT_AUTHOR_NAME}"
EMAIL="${GIT_AUTHOR_EMAIL}"

# Re-disable co-author hook in case Cursor re-injected it
HOOKS_PATH="$(git config --get core.hooksPath 2>/dev/null || true)"
if [[ -n "$HOOKS_PATH" && -x "$HOOKS_PATH/commit-msg.cursor.co-author" ]]; then
  chmod -x "$HOOKS_PATH/commit-msg.cursor.co-author" || true
fi

exec git \
  -c "user.name=${NAME}" \
  -c "user.email=${EMAIL}" \
  -c commit.gpgsign=false \
  commit "$@"
