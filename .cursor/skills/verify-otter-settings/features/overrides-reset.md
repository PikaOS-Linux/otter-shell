# Overrides and reset

Overrides and reset let a user apply root theme overrides and then restore inheritance so Settings returns to the selected layer values.

## Sub-features

- `root-override` shows Current/Bank with root overrides applied.
- `reset-inheritance` shows the same profiles after reset clears those overrides.

## How to get to it (user POV)

- Open otter-settings Theme browser.
- Change a root-level override value.
- Choose Reset so the field inherits from the selected layer again.

## Driving it with verify-otter-settings

Preconditions:

- `scripts/doctor.sh` exits `0`.
- Baselines include `current-overrides@1x`, `bank-overrides@1x`, `current-reset@1x`, `bank-reset@1x`.

- **CPU gate.** Run `scripts/run-visual-test.sh <run-id>`. Exit code `0`.
- **Override state.** Confirm `current-overrides@1x.png` and `bank-overrides@1x.png` exist in artifacts.
- **Reset state.** Confirm `current-reset@1x.png` and `bank-reset@1x.png` exist and matched their baselines (reset must not equal a leftover override baseline).
- **Proof.** Retain `result.txt` and the four PNGs.

## Gotchas

- Override and reset fixtures are paired; proving only override is incomplete when the map lists reset.
- Reset fixtures still set `override = true` then apply reset in the fixture builder — do not skip them because the name says reset.
- Never validate by editing `visual/baselines/*-reset@1x.png` during a verify run.
