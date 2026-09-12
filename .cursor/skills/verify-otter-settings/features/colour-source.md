# Colour source

Colour source lets a user see Settings themed from the selected profile defaults or from wallpaper-generated colours, including a full-shell generated accent surface.

## Sub-features

- `profile-default` renders Current and Bank at profile defaults.
- `generated-browser` renders the generated colour source without forcing full shell chrome emphasis.
- `generated-shell` renders the generated source with full shell chrome.

## How to get to it (user POV)

- Open otter-settings Theme browser on Current or Bank.
- Switch the colour source between the profile default and wallpaper-generated colours.

## Driving it with verify-otter-settings

Preconditions:

- `scripts/doctor.sh` exits `0`.
- Baselines include `current-default@1x`, `bank-default@1x`, `current-generated@1x`, `bank-generated@1x`, `current-generated-shell@1x`.

- **CPU gate.** Run `scripts/run-visual-test.sh <run-id>`. Exit code `0`.
- **Default vs generated.** Confirm artifacts contain both `current-default@1x.png` and `current-generated@1x.png` (and Bank siblings). Generated frames must differ from defaults (pixel mismatch against the other fixture is expected; each must still match its own baseline).
- **Full-shell generated.** Confirm `current-generated-shell@1x.png` is present and matched.
- **Proof.** `result.txt` exit `0` with those five PNGs retained under the run-id.

## Gotchas

- Generated fixtures inject fixed synthetic colours in `visual_fixture.zig`; they do not read a live wallpaper.
- Bank and Current both have generated cases; failing only one still fails the gate.
- Optional live smoke shows whatever theme files the isolated XDG tree provides — not a substitute for generated fixtures.
