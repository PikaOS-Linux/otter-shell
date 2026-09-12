# Narrow and HiDPI

Narrow and HiDPI let a user run Settings in a compact viewport and at 2x scale without clipped controls or wrong layout density.

## Sub-features

- `narrow-1x` shows Current and Bank at 420×300 logical pixels.
- `narrow-2x` shows Current narrow at scale 2.

## How to get to it (user POV)

- Resize otter-settings to a narrow window.
- Run on a 2x output (or scale factor 2).

## Driving it with verify-otter-settings

Preconditions:

- `scripts/doctor.sh` exits `0`.
- Baselines include `current-narrow@1x`, `bank-narrow@1x`, `current-narrow@2x`.

- **CPU gate.** Run `scripts/run-visual-test.sh <run-id>`. Exit code `0`.
- **Narrow 1x.** Confirm `current-narrow@1x.png` and `bank-narrow@1x.png` matched.
- **Narrow 2x.** Confirm `current-narrow@2x.png` matched (pixel dimensions are 2× the 1x narrow fixture).
- **Optional live smoke.** After CPU pass, with `WAYLAND_DISPLAY` unset, run `scripts/run-live-smoke.sh <run-id>`. Confirm `live-window.png` exists and shows Settings chrome.
- **Proof.** CPU PNGs always; add `live-window.png` when the optional step ran.

## Gotchas

- 2x failures are often font or SDF radius regressions, not only layout width.
- Live smoke captures the default window size from the compositor, not the 420×300 narrow fixture — use CPU fixtures for narrow proof.
- `headless-capture.sh` requires sway+grim; doctor warns when they are missing.
