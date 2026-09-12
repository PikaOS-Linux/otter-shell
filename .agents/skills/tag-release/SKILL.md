---
name: tag-release
description: Tag otter-shell packages for release. Selective by default (only named packages + needed dep retags); --train locksteps everything. Updates build.zig.zon, tags, pushes, restores path deps, and writes otter-zenith/pins.json.
user-invocable: true
argument-hint: "<version> [--train | pkg pkg ...]  e.g. 0.11.63 otter-greeter | 0.12.0 --train"
---

# Release Tagging for Otter Shell

Workspace root: `/home/ferreo/otter-shell/` (thin submodule workspace). Each `otter-*` package is its own git repo on `git.pika-os.com/otter-shell/` — tag and push **per package**, not via the workspace root.

Pins live at `otter-zenith/pins.json`. Zenith clones/builds from those pins — keep them accurate after every release.

## Arguments

Parse `$ARGUMENTS`:

| Invocation | Meaning |
|---|---|
| `0.11.63 otter-greeter otter-lock` | Selective: tag only those packages at `v0.11.63` |
| `0.11.63 --train` or `0.11.63 --all` | Full lockstep: tag every package in the dependency tree |
| `0.11.63` alone | Treat as `--train` only if the user clearly asked for a full release; otherwise ask which packages (or confirm train) |

Version is always without a leading `v`. Tags are `v<VERSION>`.

## Pre-flight

1. Abort if version missing.
2. Abort if `v<VERSION>` already exists on any package you intend to tag.
3. For each package in the release set: commit any dirty work with a descriptive message, then push the branch.
4. Read `otter-zenith/pins.json` before starting.

## Dependency levels (tag bottom-up)

```
Level 0:  otter-geo, otter-utils
Level 1:  otter-conf (→ utils), otter-render (→ geo, utils)
Level 2:  otter-desktop (→ utils), otter-wayland (→ geo, render, utils), otter-theme (→ geo, render, conf, utils), otter-config-types (→ render, geo, conf), otter-vte (→ geo, render), otter-tools-core (→ conf, config-types, utils), otter-cue (→ desktop, utils)
Level 3:  otter-ui (→ geo, render, vte, theme, wayland, utils, desktop, tools-core)
Level 4:  apps — otter-bar, otter-launcher, otter-files, otter-dock, otter-taskbar, otter-search, otter-assist, otter-assistant, otter-notifications, otter-wallpaper, otter-osd, otter-jade, otter-logout, otter-overview, otter-keybindhelp, otter-pkg, otter-polkit, otter-lock, otter-greeter, otter-idle, otter-nightlight, otter-monitor, otter-settings, otter-theme-gen, otter-term, otter-screenshot, otter-clicker, otter-shot, otter-cal, otter-calc, otter-clip, otter-rec, otter-pick, otter-emoji, otter-timer, otter-note, otter-weather, otter-transcribe, otter-vox
Level 4½: plugin/CLI packages — otter-bluetooth-plugin, otter-shell-plugins, otter-plugin-factory (still part of --train / full set)
```

### Phase 0 shared-lib sources (required on `--train` / full release)

These Level 0–3 libs ship SONAME `.0` packages via zenith (`libotter-*-0`). A full
train **must** include them so pins and shared packaging stay lockstepped:

- `otter-utils`, `otter-geo`, `otter-render`, `otter-theme`, `otter-ui`

They are already in the levels above — call them out explicitly when planning a
`--train` so shared packaging is never skipped by accident.

The first `otter-dock` and `otter-taskbar` tags must be part of a full
`--train` release that bumps every Level 0–3 library. After their first pins
exist, normal selective app releases are allowed.

### Expanding a selective set

When the user names packages (not `--train`):

1. Start with the named set.
2. Read each named package’s `build.zig.zon` and collect internal `.path = "../otter-*"` deps.
3. **Do not** automatically retag every dependency. Only add a dependency to the release set if:
   - the user named it, or
   - it has uncommitted/unpushed commits that should ship, or
   - the user asked to “rebuild consumers” of a lib you are tagging.
4. If tagging a **library** and the user wants consumers updated, expand to apps/libs whose `build.zig.zon` path-deps include that library (use the checklist below). Ask before expanding to the entire app set.
5. Sort the final set by level (0→4½) and process level by level.

`--train` = every package in the tree above (including `otter-bluetooth-plugin`, `otter-shell-plugins`, and `otter-plugin-factory`).

`otter-plugin-factory` is the Zig `opf` CLI (scaffold/pack/check). Include it on
`--train` / full set alongside both plugin packages; zenith packs it by default.
No `build.zig.zon` — tag `v<VERSION>` on a clean main tip (no path-dep rewrite).

## Manifest version rule

Before tagging a package, set top-level `.version` in `build.zig.zon`:

- Normal packages: `.version = "<VERSION>"`
- `otter-conf` only: add 1 to the first numeric component (`0.10.42` → `1.10.42`)
- Tags are always `v<VERSION>` (including otter-conf)
- Keep `.version` after restore (do not revert versions when restoring path deps)

`otter-shell-plugins` may use the same versioning/tag flow even when it has no
internal otter path deps — still set `.version`, tag `v<VERSION>`, and pin it.

`otter-bluetooth-plugin` uses workspace directory and source repository
`bluetooth-applet-plugin`, but its Zenith pin and Debian binary package are
named `otter-bluetooth-plugin`.

## Process per package in the release set

For each package, in level order:

1. Read `build.zig.zon` (skip path-dep rewrite steps that do not apply if none). Derive internal deps from every `.path = "../otter-*"` (checklist below is a cross-check, not source of truth).
2. Update `.version` (manifest rule).
3. Replace every **internal** path dep that has **already been tagged in this run** (or already has a pin you are intentionally consuming) with URL+hash:
   ```zig
   .otter_foo = .{
       .url = "git+https://git.pika-os.com/otter-shell/otter-foo.git#v<DEP_VERSION>",
       .hash = "<hash from zig fetch>",
   },
   ```
   - On `--train`, `<DEP_VERSION>` is the release version for every internal dep.
   - On selective releases: for deps **in this release set**, use the new version; for deps **not** in the set, either keep `.path` (only OK if you will not push a tag that still has path deps — **tags must never contain path deps**) or convert them to the **current pin** from `pins.json` (URL+hash via `zig fetch` of that pinned tag). Prefer converting non-released deps to their existing pin so the tag is self-contained.
4. Preserve external deps (zigimg, wayland, zeit, vendored paths) unchanged.
5. Verify no `.path = "../otter-*"` remain before tagging.
6. Commit: `build: update version and deps for v<VERSION> tag`
7. `git tag v<VERSION> && git push && git push origin v<VERSION>`
8. `zig fetch "git+https://git.pika-os.com/otter-shell/<package>.git#v<VERSION>"` (60s timeout) — store hash for dependents in this run.

## Restore (release-set only)

After tagging, for **each package in the release set only**:

1. Convert internal URL+hash deps back to `.path = "../otter-*"`
2. Keep external deps and `.version` unchanged
3. Commit: `build: restore local path deps after v<VERSION> tagging`
4. Push

Do **not** touch repos outside the release set.

## Update pins.json

After a successful release:

```bash
python3 otter-zenith/scripts/bump-pins.py [--train <VERSION>] pkg=VERSION pkg=VERSION ...
```

- Selective: pass each tagged package (`otter-greeter=0.11.63` …). Do **not** change `train` unless the user asked.
- `--train`: pass every package (including `otter-bluetooth-plugin`, `otter-shell-plugins`, `otter-plugin-factory`, and the Phase 0 shared-lib sources) and `--train <VERSION>`.
- On a package's first release, also add it to `pins.clone`; this applies to `otter-dock` and `otter-taskbar` when their first tags are created.
- After the first `otter-bluetooth-plugin` tag, remove its fixed entry from `pins.refs`; tagged releases use its normal package pin.
- Commit + push the `otter-zenith` repo: `pins: bump <packages> to v<VERSION>`

Also set `packages.otter-assist-data` to the same version as `otter-assist` when assist is tagged (virtual pin for packaging).

## Post-verify

1. For every tagged package: `git show v<VERSION>:build.zig.zon` has the right `.version` and **no** `.path = "../otter-*"` entries.
2. For every restored branch: path deps restored, `.version` kept, no leftover release URLs for this version.
3. `pins.json` matches the tags you just pushed.
4. Print a summary table: package, tag, pin before → after.

## Zenith post-tag builds

After pins are updated:

- **Normal full / cockatiel** `./main.sh` (empty `BUILD_PACKAGES`) now builds
  **Phase 0 shared libs + `otter-bluetooth-plugin` + `otter-shell-plugins` + `otter-plugin-factory` by default**
  (`BUILD_SHARED_LIBS` defaults to `1`; plugins/factory are in the default
  clone/`ZIG_PACKAGES` set).
- **Selective hotfixes**: `BUILD_PACKAGES=otter-greeter ./main.sh`. Optionally
  `BUILD_SHARED_LIBS=0` (or rely on `auto` → off when the selective set has no
  bar/launcher/`libotter-*`).
- Metas-only stays light: `BUILD_META_ONLY=1` forces shared libs off.

## Internal dependency checklist

| Package | Internal path deps |
|---|---|
| otter-geo | (none) |
| otter-utils | (none) |
| otter-conf | otter-utils |
| otter-render | otter-geo, otter-utils |
| otter-desktop | otter-utils |
| otter-cue | otter-desktop, otter-utils |
| otter-wayland | otter-geo, otter-render, otter-utils |
| otter-theme | otter-geo, otter-render, otter-conf, otter-utils |
| otter-config-types | otter-render, otter-geo, otter-conf |
| otter-vte | otter-geo, otter-render |
| otter-tools-core | otter-conf, otter-config-types, otter-utils |
| otter-ui | otter-geo, otter-render, otter-vte, otter-theme, otter-wayland, otter-utils, otter-desktop, otter-tools-core |
| otter-bar | otter-geo, otter-utils, otter-render, otter-wayland, otter-ui, otter-desktop, otter-conf, otter-theme, otter-config-types |
| otter-launcher | otter-geo, otter-utils, otter-render, otter-wayland, otter-desktop, otter-conf, otter-ui, otter-theme, otter-config-types, otter-tools-core |
| otter-files | otter-conf, otter-desktop, otter-geo, otter-render, otter-theme, otter-ui, otter-utils, otter-wayland; external libssh and libwebp |
| otter-dock | otter-geo, otter-utils, otter-render, otter-wayland, otter-ui, otter-desktop, otter-conf, otter-theme, otter-config-types |
| otter-taskbar | otter-geo, otter-utils, otter-render, otter-wayland, otter-ui, otter-desktop, otter-conf, otter-theme, otter-config-types |
| otter-search | otter-utils, otter-conf, otter-tools-core |
| otter-assist | otter-utils, otter-conf, otter-config-types, otter-tools-core |
| otter-assistant | otter-geo, otter-utils, otter-render, otter-wayland, otter-conf, otter-theme, otter-tools-core, otter-ui |
| otter-notifications | otter-geo, otter-utils, otter-render, otter-wayland, otter-desktop, otter-conf, otter-theme, otter-ui, otter-config-types |
| otter-wallpaper | otter-geo, otter-utils, otter-render, otter-wayland, otter-conf, otter-theme, otter-ui, otter-config-types |
| otter-osd | otter-geo, otter-utils, otter-render, otter-wayland, otter-desktop, otter-conf, otter-theme, otter-ui, otter-config-types |
| otter-jade | otter-geo, otter-utils, otter-render, otter-wayland, otter-conf, otter-theme, otter-ui, otter-config-types |
| otter-logout | otter-geo, otter-utils, otter-render, otter-wayland, otter-desktop, otter-conf, otter-theme, otter-ui, otter-config-types |
| otter-overview | otter-geo, otter-utils, otter-render, otter-wayland, otter-desktop, otter-conf, otter-theme, otter-ui, otter-config-types |
| otter-keybindhelp | otter-utils, otter-geo, otter-render, otter-theme, otter-wayland, otter-ui |
| otter-pkg | otter-utils, otter-geo, otter-render, otter-theme, otter-wayland, otter-ui, otter-desktop; external vendored zapt/apt-dpkg-libs |
| otter-polkit | otter-geo, otter-utils, otter-render, otter-wayland, otter-desktop, otter-conf, otter-theme, otter-ui, otter-config-types |
| otter-lock | otter-geo, otter-utils, otter-render, otter-wayland, otter-desktop, otter-conf, otter-theme, otter-ui, otter-config-types |
| otter-greeter | otter-geo, otter-utils, otter-render, otter-wayland, otter-desktop, otter-conf, otter-theme, otter-ui, otter-config-types |
| otter-idle | otter-utils, otter-wayland, otter-desktop, otter-conf, otter-config-types |
| otter-nightlight | otter-utils, otter-wayland, otter-conf, otter-config-types, otter-tools-core |
| otter-monitor | otter-geo, otter-utils, otter-render, otter-wayland, otter-conf, otter-ui, otter-theme, otter-desktop, otter-config-types |
| otter-settings | otter-geo, otter-utils, otter-render, otter-wayland, otter-conf, otter-ui, otter-theme, otter-config-types, otter-tools-core |
| otter-theme-gen | otter-utils, otter-tools-core, otter-conf, otter-theme, otter-config-types, otter-render |
| otter-term | otter-geo, otter-utils, otter-render, otter-wayland, otter-theme, otter-conf, otter-config-types, otter-ui, otter-vte |
| otter-screenshot | otter-render, otter-theme, otter-wayland, otter-utils |
| otter-clicker | otter-wayland, otter-conf, otter-config-types, otter-theme, otter-utils |
| otter-shot | otter-geo, otter-utils, otter-render, otter-wayland, otter-theme, otter-desktop, otter-ui, otter-conf, otter-tools-core |
| otter-cal | otter-tools-core |
| otter-calc | otter-tools-core |
| otter-clip | otter-tools-core, otter-utils, otter-wayland |
| otter-rec | otter-tools-core, otter-utils, otter-desktop, otter-theme, otter-wayland |
| otter-pick | otter-tools-core, otter-render, otter-wayland, otter-theme, otter-utils |
| otter-emoji | otter-tools-core |
| otter-timer | otter-tools-core, otter-utils |
| otter-note | otter-tools-core, otter-utils, otter-geo, otter-render, otter-theme, otter-wayland, otter-ui |
| otter-weather | otter-tools-core, otter-utils, otter-geo, otter-render, otter-theme, otter-wayland, otter-ui |
| otter-transcribe | otter-utils, otter-geo, otter-render, otter-wayland, otter-conf, otter-theme, otter-ui, otter-config-types |
| otter-vox | otter-tools-core, otter-utils, otter-desktop |
| otter-bluetooth-plugin | otter-ui, otter-wayland, otter-theme, otter-desktop (source repo: bluetooth-applet-plugin) |
| otter-shell-plugins | (none — examples package; include on `--train`) |
| otter-plugin-factory | (none — Zig CLI; tag clean main; include on `--train`) |

## URL format

`git+https://git.pika-os.com/otter-shell/<package>.git#v<VERSION>`

For `otter-bluetooth-plugin`, replace `<package>` with `bluetooth-applet-plugin`.

## Important rules

- Never add Co-Authored-By lines.
- `zig fetch` timeout 60000ms.
- Never tag a package before its release-set dependencies are tagged and hashed.
- Tags must not contain `.path = "../otter-*"` deps.
- Selective releases must not rewrite or retag packages outside the set.
- After tagging, zenith: full train dumps use `./main.sh` / `BUILD_EXTRAS=1 ./main.sh` (shared libs + both plugin packages + otter-plugin-factory on by default). Hotfixes: `BUILD_PACKAGES=otter-greeter ./main.sh` (optionally `BUILD_SHARED_LIBS=0`).
