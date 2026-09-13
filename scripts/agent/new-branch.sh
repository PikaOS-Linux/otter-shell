#!/usr/bin/env bash
# Create a fer/<slug> branch from the package default base (main or master).
# Howard wrote "/fer" — we use prefix fer/<topic> (see docs/agent-gitea-helpers.md).
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: new-branch.sh <package-dir> <slug> [--worktree <path>]

Creates branch fer/<slug> from origin/<default>.
Slug is lowercased; spaces become hyphens; leading fer/ is stripped if present.
EOF
  exit 2
}

[[ $# -ge 2 ]] || usage
PKG="$1"
SLUG_RAW="$2"
shift 2
WORKTREE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --worktree) WORKTREE="$2"; shift 2 ;;
    *) usage ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG="$(cd "$PKG" && pwd)"

# shellcheck disable=SC1091
source "${XDG_RUNTIME_DIR:-/tmp}/otter-gitea-ssh.env" 2>/dev/null || true
if [[ -z "${GIT_SSH_COMMAND:-}" ]]; then
  "$SCRIPT_DIR/gitea-ssh-bootstrap.sh" >/dev/null
  # shellcheck disable=SC1091
  source "${XDG_RUNTIME_DIR:-/tmp}/otter-gitea-ssh.env"
fi

slug="$(printf '%s' "$SLUG_RAW" | tr '[:upper:]' '[:lower:]' | sed -E 's|^fer/||; s/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
[[ -n "$slug" ]] || { echo "error: empty slug" >&2; exit 1; }
branch="fer/${slug}"

default="$("$SCRIPT_DIR/default-branch.sh" "$PKG")"
git -C "$PKG" fetch origin "$default"
base="origin/${default}"

if [[ -n "$WORKTREE" ]]; then
  git -C "$PKG" worktree add "$WORKTREE" -b "$branch" "$base"
  echo "ok: worktree $WORKTREE on $branch (base $base)"
else
  git -C "$PKG" checkout -B "$branch" "$base"
  echo "ok: checked out $branch (base $base)"
fi
