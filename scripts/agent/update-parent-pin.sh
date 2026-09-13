#!/usr/bin/env bash
# Bump a parent workspace submodule pin and commit on the parent repo.
# Pushes to the Gitea remote named "gitea" (not GitHub origin).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PKG_NAME="${1:?usage: update-parent-pin.sh <package-name> [commit-ish]}"
COMMITISH="${2:-}"

# shellcheck disable=SC1091
source "${XDG_RUNTIME_DIR:-/tmp}/otter-gitea-ssh.env" 2>/dev/null || true
if [[ -z "${GIT_SSH_COMMAND:-}" ]]; then
  "$SCRIPT_DIR/gitea-ssh-bootstrap.sh" >/dev/null
  # shellcheck disable=SC1091
  source "${XDG_RUNTIME_DIR:-/tmp}/otter-gitea-ssh.env"
fi

"$SCRIPT_DIR/git-identity-ferreo.sh" >/dev/null
# shellcheck disable=SC1091
source "${XDG_RUNTIME_DIR:-/tmp}/otter-git-identity-ferreo.env"

PKG_PATH="$ROOT/$PKG_NAME"
[[ -e "$PKG_PATH" ]] || { echo "error: missing $PKG_PATH" >&2; exit 1; }

if [[ -n "$COMMITISH" ]]; then
  git -C "$PKG_PATH" fetch origin
  git -C "$PKG_PATH" checkout --detach "$COMMITISH"
fi

# Ensure parent has a gitea remote
if ! git -C "$ROOT" remote get-url gitea >/dev/null 2>&1; then
  git -C "$ROOT" remote add gitea "git@${GITEA_SSH_HOST:-ssh.pika-os.com}:otter-shell/otter-shell.git"
fi

git -C "$ROOT" add "$PKG_NAME"
sha="$(git -C "$PKG_PATH" rev-parse --short HEAD)"
"$SCRIPT_DIR/commit.sh" -m "chore: bump ${PKG_NAME} pin (${sha})"

echo "ok: parent pin updated for $PKG_NAME @ $sha"
echo "hint: git -C $ROOT push -u gitea HEAD   # do not push package pins to GitHub origin as SoT"
