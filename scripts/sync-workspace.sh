#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

git submodule sync --recursive
git submodule update --init --recursive

if [[ "${1:-}" == "--remote" ]]; then
  git submodule update --remote --merge
fi

echo
git submodule status
