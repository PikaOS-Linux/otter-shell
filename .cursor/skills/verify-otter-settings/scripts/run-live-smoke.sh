#!/usr/bin/env bash
set -euo pipefail

SETTINGS="${SETTINGS:-/home/ferreo/otter-shell/otter-settings}"
UI="${UI:-/home/ferreo/otter-shell/otter-ui}"
SKILL="${SKILL:-/home/ferreo/otter-shell/.cursor/skills/verify-otter-settings}"
RUN_ID="${1:-}"
if [[ -z "$RUN_ID" ]]; then
  echo "usage: run-live-smoke.sh <run-id>" >&2
  exit 2
fi

if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  echo "run-live-smoke: refuse: WAYLAND_DISPLAY=$WAYLAND_DISPLAY already set (would risk user session)" >&2
  exit 1
fi

for bin in sway grim swaymsg dbus-run-session; do
  command -v "$bin" >/dev/null 2>&1 || {
    echo "run-live-smoke: missing $bin" >&2
    exit 1
  }
done

OUT="$SKILL/artifacts/$RUN_ID"
mkdir -p "$OUT"

BIN="$SETTINGS/zig-out/bin/otter-settings"
if [[ ! -x "$BIN" ]]; then
  (cd "$SETTINGS" && zig build -Doptimize=ReleaseFast)
fi

CAPTURE="$UI/tools/headless-capture.sh"
PNG="$OUT/live-window.png"

{
  echo "cmd: $CAPTURE --profile current --density standard --out $PNG -- $BIN"
  echo "started: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >>"$OUT/result.txt"

set +e
"$CAPTURE" --profile current --density standard --out "$PNG" -- "$BIN" >>"$OUT/result.txt" 2>&1
rc=$?
set -e

{
  echo "live_finished: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "live_exit_code: $rc"
} >>"$OUT/result.txt"

# Capture script may leave sibling logs next to --out on failure.
for sibling in "$PNG.sway.log" "$PNG.app.log" "$PNG.pids"; do
  [[ -e "$sibling" ]] && cp -a "$sibling" "$OUT/" || true
done
# Also check bare names without .png prefix variants some scripts use
for sibling in "${PNG%.png}.sway.log" "${PNG%.png}.app.log"; do
  [[ -e "$sibling" ]] && cp -a "$sibling" "$OUT/" || true
done

if [[ "$rc" -ne 0 ]]; then
  echo "run-live-smoke: failed (exit $rc); evidence at $OUT" >&2
  exit "$rc"
fi

echo "run-live-smoke: ok; evidence at $OUT/live-window.png"
exit 0
