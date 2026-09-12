# Theme section tabs

Theme section tabs let a user inspect each four-layer theme surface — Colours, Layout, Spacing, and Globals — inside the Settings theme browser chrome.

## Sub-features

- `theme-colours` shows the Colours section with Current profile full shell.
- `theme-layout` shows the Layout section.
- `theme-spacing` shows the Spacing section.
- `theme-globals` shows the Globals section.

## How to get to it (user POV)

- Open otter-settings and choose the Theme browser.
- Select the Colours, Layout, Spacing, or Globals section control.

## Driving it with verify-otter-settings

Preconditions:

- `scripts/doctor.sh` exits `0`.
- Committed baselines include `theme-colours@1x.png`, `theme-layout@1x.png`, `theme-spacing@1x.png`, `theme-globals@1x.png`.

- **CPU gate.** Run the full visual matrix. Run `scripts/run-visual-test.sh <run-id>`. Exit code `0`.
- **Confirm section fixtures.** Inspect artifacts. Confirm `$SKILL/artifacts/<run-id>/zig-out-visual/theme-colours@1x.png` (and layout/spacing/globals siblings) exist and matched baselines per `result.txt`.
- **Proof.** Keep `result.txt` plus the four theme-*.png copies under the run-id directory.

## Gotchas

- Section fixtures share `full_shell = true`; a chrome regression can fail all four at once.
- Do not regenerate baselines to silence a mismatch during verify.
- Live window smoke does not select tabs; use CPU fixtures for section proof.
