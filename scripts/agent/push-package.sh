#!/usr/bin/env bash
# Push the current package branch to Gitea origin (SSH).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG="${1:-.}"
PKG="$(cd "$PKG" && pwd)"

# shellcheck disable=SC1091
source "${XDG_RUNTIME_DIR:-/tmp}/otter-gitea-ssh.env" 2>/dev/null || true
if [[ -z "${GIT_SSH_COMMAND:-}" ]]; then
  "$SCRIPT_DIR/gitea-ssh-bootstrap.sh" >/dev/null
  # shellcheck disable=SC1091
  source "${XDG_RUNTIME_DIR:-/tmp}/otter-gitea-ssh.env"
fi

url="$(git -C "$PKG" remote get-url origin)"
case "$url" in
  *ssh.pika-os.com*|*git.pika-os.com*) ;;
  *github.com*)
    echo "error: origin is GitHub ($url); reset to Gitea SSH first" >&2
    exit 1
    ;;
  *)
    echo "warn: unexpected origin: $url" >&2
    ;;
esac

branch="$(git -C "$PKG" rev-parse --abbrev-ref HEAD)"
case "$branch" in
  fer/*) ;;
  *)
    echo "error: branch must start with fer/ (got: $branch)" >&2
    exit 1
    ;;
esac

git -C "$PKG" push -u origin "HEAD:refs/heads/${branch}"
echo "ok: pushed ${branch} → ${url}"
