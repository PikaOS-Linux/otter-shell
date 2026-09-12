#!/usr/bin/env bash
set -euo pipefail

SETTINGS="${SETTINGS:-/home/ferreo/otter-shell/otter-settings}"
SKILL="${SKILL:-/home/ferreo/otter-shell/.cursor/skills/verify-otter-settings}"
RUN_ID="${1:-}"
if [[ -z "$RUN_ID" ]]; then
  echo "usage: run-visual-test.sh <run-id>" >&2
  exit 2
fi

OUT="$SKILL/artifacts/$RUN_ID"
mkdir -p "$OUT/zig-out-visual"

{
  echo "cmd: cd $SETTINGS && zig build -Doptimize=ReleaseFast visual-test"
  echo "started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >"$OUT/result.txt"

set +e
(
  cd "$SETTINGS"
  zig build -Doptimize=ReleaseFast visual-test
) >>"$OUT/result.txt" 2>&1
rc=$?
set -e

{
  echo "finished: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "exit_code: $rc"
} >>"$OUT/result.txt"

if [[ -d "$SETTINGS/zig-out/visual" ]]; then
  cp -a "$SETTINGS/zig-out/visual/." "$OUT/zig-out-visual/" || true
fi

if [[ "$rc" -ne 0 ]]; then
  echo "run-visual-test: visual-test failed (exit $rc); evidence at $OUT" >&2
  exit "$rc"
fi

echo "run-visual-test: ok; evidence at $OUT"
exit 0
