#!/usr/bin/env bash
set -euo pipefail

SETTINGS="${SETTINGS:-/home/ferreo/otter-shell/otter-settings}"
UI="${UI:-/home/ferreo/otter-shell/otter-ui}"
FONT="/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BASELINES="$SETTINGS/visual/baselines"
EXPECTED_BASELINES=18
fail=0

say() { printf 'doctor: %s\n' "$*"; }
bad() { printf 'doctor: FAIL: %s\n' "$*" >&2; fail=1; }

zig_ver=$(zig version 2>/dev/null || true)
case "$zig_ver" in
  0.16.*) say "zig $zig_ver" ;;
  *) bad "need zig 0.16.x, got '${zig_ver:-missing}'" ;;
esac

if [[ -f "$FONT" ]]; then
  say "font pin ok: $FONT"
else
  bad "missing fixture font: $FONT"
fi

if [[ ! -d "$BASELINES" ]]; then
  bad "missing baselines dir: $BASELINES"
else
  count=$(find "$BASELINES" -maxdepth 1 -name '*.png' | wc -l)
  if [[ "$count" -eq "$EXPECTED_BASELINES" ]]; then
    say "baselines: $count pngs"
  else
    bad "baselines expected $EXPECTED_BASELINES pngs, found $count in $BASELINES"
  fi
fi

for bin in sway grim swaymsg dbus-run-session; do
  if command -v "$bin" >/dev/null 2>&1; then
    say "live dep ok: $bin"
  else
    say "live dep missing (CPU fixtures still ok): $bin"
  fi
done

if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  say "WAYLAND_DISPLAY=$WAYLAND_DISPLAY is set — refuse live smoke until unset; CPU visual-test is fine"
fi

if [[ -x "$UI/tools/headless-capture.sh" ]]; then
  say "headless-capture present"
else
  say "headless-capture missing at $UI/tools/headless-capture.sh (live smoke unavailable)"
fi

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi
say "ready"
exit 0
