#!/usr/bin/env bash
# Print the default branch for a package directory or Gitea SSH URL.
# Preference order:
#   1. .gitmodules branch= for this path (workspace root)
#   2. origin/HEAD symref (after fetch)
#   3. git ls-remote --symref HEAD
#   4. sole main or master head
set -euo pipefail

usage() {
  echo "usage: $0 <package-dir|owner/repo|ssh-url>" >&2
  exit 2
}

[[ $# -eq 1 ]] || usage
TARGET="$1"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

resolve_from_gitmodules() {
  local pkg="$1"
  git -C "$ROOT" config -f "$ROOT/.gitmodules" --get "submodule.${pkg}.branch" 2>/dev/null || true
}

resolve_url() {
  local url="$1"
  local out symref
  out="$(git ls-remote --symref "$url" HEAD 2>/dev/null || true)"
  symref="$(printf '%s\n' "$out" | awk '/^ref:/ {print $2; exit}')"
  if [[ -n "$symref" ]]; then
    echo "${symref##*/}"
    return 0
  fi
  local refs has_main has_master
  refs="$(git ls-remote --heads "$url" 2>/dev/null || true)"
  has_main=$(printf '%s\n' "$refs" | grep -c 'refs/heads/main$' || true)
  has_master=$(printf '%s\n' "$refs" | grep -c 'refs/heads/master$' || true)
  if [[ "$has_main" -eq 1 && "$has_master" -eq 0 ]]; then
    echo main
    return 0
  fi
  if [[ "$has_master" -eq 1 && "$has_main" -eq 0 ]]; then
    echo master
    return 0
  fi
  echo "error: cannot infer default branch for $url" >&2
  return 1
}

if [[ -d "$TARGET/.git" || -f "$TARGET/.git" ]]; then
  pkg="$(basename "$(cd "$TARGET" && pwd)")"
  from_gm="$(resolve_from_gitmodules "$pkg")"
  if [[ -n "$from_gm" ]]; then
    echo "$from_gm"
    exit 0
  fi
  sym="$(git -C "$TARGET" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [[ -n "$sym" ]]; then
    echo "${sym##*/}"
    exit 0
  fi
  url="$(git -C "$TARGET" remote get-url origin)"
  resolve_url "$url"
  exit $?
fi

if [[ "$TARGET" == git@*:* || "$TARGET" == ssh://* ]]; then
  resolve_url "$TARGET"
  exit $?
fi

# Treat as package name under workspace
if [[ -d "$ROOT/$TARGET" ]]; then
  from_gm="$(resolve_from_gitmodules "$TARGET")"
  if [[ -n "$from_gm" ]]; then
    echo "$from_gm"
    exit 0
  fi
fi

# owner/repo shorthand
if [[ "$TARGET" == */* && "$TARGET" != /* ]]; then
  host="${GITEA_SSH_HOST:-ssh.pika-os.com}"
  resolve_url "git@${host}:${TARGET}.git"
  exit $?
fi

echo "error: unknown target: $TARGET" >&2
exit 1
