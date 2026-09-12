---
name: verify-otter-settings
description: "Drive otter-settings the way a user does: CPU visual fixtures against committed baselines, optional isolated headless Sway/Grim window smoke. Use when proving Settings/theme UI changes, visual regressions, or live window launch without touching the user's Wayland session."
---

# Verify otter-settings

Agent-facing control skill for **otter-settings** (XDG toplevel theme/config editor). Prefer the CPU fixture harness; only use headless Sway when a real compositor surface is required. Never attach to the user's live `WAYLAND_DISPLAY` or write under their real `~/.config/otter-shell`.

Repo roots used below:

- `SETTINGS=/home/ferreo/otter-shell/otter-settings`
- `UI=/home/ferreo/otter-shell/otter-ui`
- `SKILL=/home/ferreo/otter-shell/.cursor/skills/verify-otter-settings`
- Evidence always lands in `$SKILL/artifacts/<run-id>/` and **must survive cleanup**.

## Launch

CPU path (default — no compositor):

```bash
cd /home/ferreo/otter-shell/otter-settings
zig build -Doptimize=ReleaseFast
# Ready when zig-out/bin/otter-settings-visual-fixture exists after a visual step, or when visual-test exits 0.
```

Live window path (isolated only):

```bash
cd /home/ferreo/otter-shell/otter-settings
zig build -Doptimize=ReleaseFast
RUN_ID=$(date -u +%Y%m%dT%H%M%SZ)
OUT="$SKILL/artifacts/$RUN_ID"
mkdir -p "$OUT"
# headless-capture invents XDG_* + WAYLAND_DISPLAY under /tmp/otter-headless.*
"$UI/tools/headless-capture.sh" --profile current --density standard \
  --out "$OUT/live-window.png" -- \
  "$SETTINGS/zig-out/bin/otter-settings"
```

Ready signals for live capture (enforced by `headless-capture.sh`):

1. Wayland socket appears under the temp `XDG_RUNTIME_DIR` and `swaymsg -t get_version` works.
2. App still alive and `swaymsg -t get_tree` shows a non-zero `"pid"` within ~10s.

Teardown for live path: the capture script's trap kills only PIDs it started (tracked in `$root/created-pids`). Do not `pkill otter-settings` / `pkill sway`.

For short CPU runs there is no long-lived process — launch means build once, then drive fixtures.

## Doctor

Run before any drive when something looks off:

```bash
"$SKILL/scripts/doctor.sh"
```

Doctor is read-only. It checks:

- `zig` reports `0.16.0`
- font pin `/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf` exists (fixture hard-requires it)
- committed baselines exist at `$SETTINGS/visual/baselines/*.png` (18 fixtures)
- for optional live smoke: `sway`, `grim`, `swaymsg`, `dbus-run-session` on `PATH`
- refuses if `WAYLAND_DISPLAY` is already set in the agent environment when about to run live capture (unset it / use a clean shell so capture owns the display)

Exit `0` = worth driving. Non-zero = fix env before continuing.

## Drive

Read `$SKILL/features/README.md`, then the matching feature file. Default proof for Settings work:

```bash
RUN_ID=$(date -u +%Y%m%dT%H%M%SZ)
"$SKILL/scripts/run-visual-test.sh" "$RUN_ID"
```

That runs `zig build -Doptimize=ReleaseFast visual-test` in `$SETTINGS` (generate `zig-out/visual/*.png` then compare to `visual/baselines/`), copies the generated PNGs plus a `result.txt` into `$SKILL/artifacts/$RUN_ID/`, and leaves baselines untouched.

Single-fixture regenerate (debug only — does not prove):

```bash
cd "$SETTINGS"
zig build -Doptimize=ReleaseFast visual-fixtures
# inspect zig-out/visual/<name>.png against visual/baselines/<name>.png
```

Do **not** run `visual-baselines` during verification; that rewrites committed goldens.

Live smoke (optional second gate after CPU pass):

```bash
"$SKILL/scripts/run-live-smoke.sh" "$RUN_ID"
```

Stable handles for the fixture matrix (names from `src/visual_fixture.zig`):

| Fixture name | User-visible state |
|---|---|
| `current-default@1x` / `bank-default@1x` | Full shell, profile default colours |
| `theme-colours@1x` / `theme-layout@1x` / `theme-spacing@1x` / `theme-globals@1x` | Theme section tabs |
| `current-generated@1x` / `current-generated-shell@1x` | Wallpaper-generated colour source |
| `current-overrides@1x` / `current-reset@1x` | Root override then reset inheritance |
| `app-overrides@1x` / `app-editing@1x` | App override + active field edit `Search here` |
| `current-narrow@1x` / `current-narrow@2x` | Narrow 420×300 viewport, 1x and 2x |

## Evidence

Proof standards:

- Exercise the real Settings draw path via the fixture binary (same widgets/theme flow as the app), not stubbed pixels.
- Capture **generate + compare** outcome: exit code, `result.txt`, and the PNGs under `$SKILL/artifacts/$RUN_ID/`.
- A green `visual-test` is the primary pass. On mismatch, keep the actual PNG and note which baseline failed; do not "fix" by regenerating baselines unless the user explicitly asked for a baseline update.
- Live smoke proof = `$OUT/live-window.png` plus any `$OUT/*.sway.log` / `$OUT/*.app.log` copied from capture failure siblings when present.
- Never treat the user's live desktop screenshot as evidence.

Artifact layout:

```
$SKILL/artifacts/<run-id>/
  result.txt          # command + exit code + zig summary
  zig-out-visual/     # copied generated PNGs
  live-window.png     # only if live smoke ran
```

## Cleanup

```bash
"$SKILL/scripts/cleanup.sh"   # optional RUN_ID arg unused; cleans only temp headless roots
```

Cleanup rules:

- Kill only PIDs recorded by `headless-capture.sh` (script already does this on exit).
- Remove leftover `/tmp/otter-headless.*` directories owned by this user that have no live PIDs.
- **Never** delete `$SKILL/artifacts/` or anything under it.
- **Never** delete `$SETTINGS/visual/baselines/`.
- **Never** unset or rewrite the user's `~/.config/otter-shell`.

## Helpers

All scripts are executable; invoke exactly as shown:

| Script | Purpose |
|---|---|
| `scripts/doctor.sh` | Read-only readiness |
| `scripts/run-visual-test.sh <run-id>` | CPU generate+compare + copy evidence |
| `scripts/run-live-smoke.sh <run-id>` | Isolated Sway/Grim window capture |
| `scripts/cleanup.sh` | Temp headless dir reclaim; keeps artifacts |

## Isolate

Two verification runs may proceed in parallel if each uses a distinct `run-id` and live capture's private `XDG_RUNTIME_DIR`. Do not double-drive a shared live Settings window. If `WAYLAND_DISPLAY` is already set to the user's session, refuse live smoke and use CPU fixtures only.
