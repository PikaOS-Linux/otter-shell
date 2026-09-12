# otter-settings verification map

This directory is the maintained source for verifying user-facing otter-settings behavior. Read the index before driving, then use the matching feature file as the recipe.

## Baseline preconditions

- Work from `/home/ferreo/otter-shell/otter-settings` with Zig `0.16.x`.
- Always use `-Doptimize=ReleaseFast` for build and visual steps.
- Run `.cursor/skills/verify-otter-settings/scripts/doctor.sh` and require exit `0` before driving.
- Prefer CPU fixtures (`visual-test`) over live windows.
- Never set `XDG_CONFIG_HOME` to the user's real config when launching live Settings.
- Never drive an instance attached to the user's existing `WAYLAND_DISPLAY`.
- Put evidence under `.cursor/skills/verify-otter-settings/artifacts/<run-id>/`.

## Driving conventions

- Start every recipe from a clean doctor pass unless the feature file says otherwise.
- Fixture names are the stable handles (`current-default@1x`, `theme-colours@1x`, …).
- Treat every command as literal. Keep paths and flags unchanged.
- CPU actions go through `scripts/run-visual-test.sh`.
- Live actions go through `scripts/run-live-smoke.sh` only when the feature asks for a compositor surface.
- Do not run `zig build visual-baselines` during a verification proof.

## Proof and skip reporting

- Capture the action (command + exit code) and the resulting PNGs, not only a pass/fail line.
- CPU proof includes `result.txt` and the copied `zig-out-visual/*.png` set.
- Live proof includes `live-window.png` with Settings chrome visible.
- Mutation of committed baselines is out of scope for verify; report mismatch and keep actuals.
- Record the feature ID and fixture names with every artifact.
- Report an unreachable path with the attempted command and unmet precondition.
- Do not report a skipped entry point as verified through a different path.

## Feature entry contract

Each feature file starts with an H1 title and one paragraph describing the user-visible behavior. It then uses exactly four H2 sections in this order.

1. `Sub-features`
2. `How to get to it (user POV)`
3. `Driving it with verify-otter-settings`
4. `Gotchas`

## Features

- [Theme section tabs](./theme-sections.md) covers Colours, Layout, Spacing, and Globals.
- [Colour source](./colour-source.md) covers profile default vs wallpaper-generated accents.
- [Overrides and reset](./overrides-reset.md) covers root overrides and reset inheritance.
- [App overrides and editing](./app-editing.md) covers per-app override and active field edit.
- [Narrow and HiDPI](./narrow-hidpi.md) covers narrow viewport and 2x scale.
