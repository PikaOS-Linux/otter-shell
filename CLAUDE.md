# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## RULES TO FOLLOW

Always write zig 0.16.0 not older zig
Always use release builds (`-Doptimize=ReleaseFast`) for build/test commands; Debug builds can segfault in large transitive compiles
Always update unit test, benchmarks, readme and this document when making changes that require it
Follow data drive design and branchless programming pattern wherever possible
Performance is critical, if something is going to hurt performance flag it up
Never add Co-Authored-By or any co-author lines to git commits

## Repository Overview

Otter Shell is a Zig-based Wayland desktop shell monorepo. The primary applications are `otter-bar` (status bar), `otter-launcher` (application launcher), `otter-files` (native file manager), `xdg-desktop-portal-otter` (XDG desktop portal backend), `otter-dock` (application dock with magnification and window previews), `otter-taskbar` (Windows-style taskbar with grouped windows, Start panel, and hover previews), `otter-term` (Ghostty-based terminal), `otter-monitor` (XDG toplevel system monitor), `otter-assistant` (AI assistant toplevel backed by `otter-assist`), `otter-assist` (local text-to-text assistant daemon on a per-Wayland-display Unix socket), `otter-notifications` (notification daemon), `otter-wallpaper` (wallpaper daemon), `otter-osd` (on-screen display daemon), `otter-transcribe` (hotkey transcription daemon with layer-shell indicator), `otter-jade` (animated layer-shell otter pet), `otter-logout` (power menu overlay), `otter-overview` (workspace and window overview overlay), `otter-polkit` (polkit authentication agent), `otter-lock` (session lockscreen), `otter-greeter` (Wayland display manager daemon and greeter UI), `otter-idle` (idle management daemon), `otter-nightlight` (gamma night-light daemon), `otter-settings` (graphical config editor and theme browser), `otter-screenshot` (region screenshot tool over `ext_image_copy_capture_v1`), `otter-search` (desktop search daemon and `otter-searchctl` CLI), `otter-shot` (Wayland product-shot composer), `otter-theme-gen` (wallpaper-reactive theme generator daemon), `otter-hypr` (Hyprland `otter-float` lua layout + `otter-hypr-titlebar` companion), and `otter-bench` (Otter HUD + Otter Bench performance suite), all using the shared component libraries.
New small-tool applications include `otter-clip`, `otter-rec`, `otter-pick`, `otter-cal`, `otter-emoji`, `otter-timer`, `otter-note`, `otter-weather`, `otter-calc`, `otter-vox`, and `otter-clicker`.

Non-application directories in the workspace: `otter-examples` (starter templates for Surface Description apps; `otter-test0` is a scratch copy of it), `otter-zenith` (Debian packaging meta-repository that clones tagged releases), `otter-site` (SvelteKit website), `zango` (wlroots 0.19 tiling compositor — separate project, not built against the shell libraries), and `zig-regex` (vendored dependency).

**Important**: The workspace root (`otter-shell/`) is a thin git repo of package **submodules**. Each package folder (`otter-bar/`, `otter-ui/`, `otter-conf/`, etc.) remains its own git repo with its own remote — commits and pushes for code changes go **per-package**, not as normal files on the root. Root commits only update docs/skills/tools or submodule SHA pins. Cloud clones need `git clone --recurse-submodules` (or `./scripts/sync-workspace.sh`).

## Build Commands

```bash
# Build and run any app
cd <component> && zig build -Doptimize=ReleaseFast run

# Run tests for any component
cd <component> && zig build -Doptimize=ReleaseFast test

# Build only
zig build -Doptimize=ReleaseFast

# Send OSD command (client mode)
cd otter-osd && zig build -Doptimize=ReleaseFast run -- volume-up 5

# Build and run terminal
cd otter-term && zig build -Doptimize=ReleaseFast run

# Build and verify desktop portal
cd xdg-desktop-portal-otter && zig build -Doptimize=ReleaseFast
cd xdg-desktop-portal-otter && zig build -Doptimize=ReleaseFast test
cd xdg-desktop-portal-otter && zig build -Doptimize=ReleaseFast integration
cd xdg-desktop-portal-otter && zig build -Doptimize=ReleaseFast real-picker-integration
cd xdg-desktop-portal-otter && zig build -Doptimize=ReleaseFast bench
cd xdg-desktop-portal-otter && zig build -Doptimize=ReleaseFast check-lines

# Benchmarks
cd otter-conf/benchmarks && zig build -Doptimize=ReleaseFast bench
cd otter-render/benchmarks && zig build -Doptimize=ReleaseFast -Dcpu=x86_64_v3 bench
cd otter-ui/benchmarks && zig build -Doptimize=ReleaseFast -Dcpu=x86_64_v3 bench
cd otter-desktop/benchmarks && zig build -Doptimize=ReleaseFast bench
cd otter-theme-gen/benchmarks && zig build -Doptimize=ReleaseFast bench
cd otter-search && zig build -Doptimize=ReleaseFast bench
cd otter-cue && zig build -Doptimize=ReleaseFast bench
cd otter-cue && zig build -Doptimize=ReleaseFast run -- --dry success
```

## Shared Libraries

| Library | Purpose |
|---------|---------|
| otter-conf | Comptime config parser (flat key-value format) |
| otter-theme | Shared visual theme (colors, spacing, popup styles, 12 presets, theme loader) |
| otter-ui | Surface Description frame API (bounded layout, hit registry, overlays, UniformList), bar widget shell (geometry/motion state), drawing primitives, text input, icon caching, scroll state, VTE wrappers |
| otter-vte | Shared terminal rendering primitives: dynamic terminal command list, powerline/block glyph ops, custom cell glyphs, generic cell renderer for embeddable terminal views |
| otter-wayland | Wayland client (layer shell, xdg_shell, session lock, workspaces, toplevel, keyboard, IME, pointer, clipboard, damage tracking, output tracking and output scale, capture selection overlay) |
| otter-config-types | Shared config struct definitions for all apps (bar, launcher, dock, taskbar, notifications, wallpaper, osd, transcribe, logout, overview, polkit, lock, idle) |
| otter-tools-core | Pure Zig bounded helpers for small tools: clipboard history, recorder encoder selection, color conversion, SplatHash sampling, semantic palette generation, calendar grids, emoji search, duration parsing, weather URL construction, calculator parsing, otter-search path/content indexing, assistant socket protocol helpers, vendored zidx knowledge retrieval, and Pika Search JSON parsing |
| otter-render | FreeType fonts, Text System boundary (HarfBuzz, itijah, Fontconfig), colors, image loading, sprite sheets, animation, CommandList + quad_renderer pipeline |
| otter-desktop | XDG icons, .desktop files, D-Bus services (UPower, MPRIS, SystemTray, NetworkManager, Logind, ScreenSaverService, etc.), SysInfo, PipeWire, PAM auth |
| otter-cue | Native Cuelume interaction-sound palette (17 synthesized cues, Bind hover/press/release/toggle, PipeWire playback via otter-desktop) |
| otter-geo | Pure geometry types (Point, Rect, Padding, Transform) |
| otter-utils | BoundedArray, logging, FilePath utilities, the app-wide `std.Io` singleton, runtime-state paths |

D-Bus (basu), PipeWire, and PAM are compile-time optional via `-Denable_dbus=false` / `-Denable_pipewire=false` / `-Denable_pam=false`. C allocator overridable with `-Dc_allocator=jemalloc` or `-Dc_allocator=mimalloc`.

## Key Design Patterns

- **Comptime Generic Parser** (otter-conf): `Parser(comptime T: type)` generates parsers at compile time. Nested struct flattening (`prefix_field` -> `config.prefix.field`), custom value types with `parse()`/`toStr()`, SIMD string scanning.
- **Global `std.Io`** (otter-utils): `otter_utils.io.install(io)` is called once from each app's `main` with the `std.Io` from `std.process.Init`; shared libraries read it back via `otter_utils.io.get()`. This keeps `io` out of library signatures while still routing I/O through the app's real `Io`. `get()` falls back to `std.Options.debug_io` when `install` has not run, so tests and one-off tools work unchanged.
- **Bar Widget Shell** (otter-ui): Bar widgets embed a `Widget` struct for shared geometry (`area`) and pointer state (`last_motion`, `full_redraw`). Layout, draw, and input call widget struct methods directly via `widget_registry` and Surface Description specs — no vtable.
- **Bar widget specs** (otter-ui): All 16 bar widgets emit frames via `otter-ui/src/widgets/specs/*.zig`; widget files own state and `drawFrame` emitters. `FieldRegistry` calls struct `getWidth`/`setArea`/`deinit` directly (child `Widget` shells hold area/motion only).
- **Bar layout** (otter-bar): `bar_layout_engine.zig` divides the bar into three fixed columns (each up to one third of inner width). Left packs LTR, center centers its group in the middle third, right packs RTL. `root_layout.zig` draws widgets and emits declarative SD rows for hits.
- **Bar input**: `bar_input_dispatch.zig` routes bar-surface pointer/scroll/click through `UiState.dispatch` plus hover-tooltip handling. Click popups (calendar, weather, volume, mpris, menus) stay until bar click or click-off overlay. `bar_popup_input.zig` handles LayerPopup surfaces.
- **Capture selection overlay** (otter-wayland): `selection_overlay.zig` is the single shared frozen/live region selector for `otter-screenshot`, `otter-shot`, and `otter-rec`, and point selector for `otter-clicker`. Uses `capture_overlay.create()` + direct SHM pixel compositing with incremental damage — **not** Surface Description. Apps pass `selection_overlay.preset.{screenshot,shot,rec,clicker}` for layer namespace and visual mode (`.frozen_unshaded` for screenshot CLI, `.frozen_dimmed` for shot/rec, transparent `.live` for clicker).
- **One output tracker** (otter-wayland): `capture/output.zig`'s `OutputList` is the only thing that *stores* output state (mode, position, transform, `wl_output.scale`, `zwlr_output_head` fractional scale, `xdg_output` logical size, name); `output_scale.Monitor` is an alias for it and `output_scale.OutputScale` is a view produced by `OutputInfo.scaleInfo()`. A second tracker briefly existed and the two disagreed by a third on a fractional display. `OutputInfo.scale` is the integer **ceiling** (2 on a 150% output); `scaleQ8()` is the exact factor, derived from mode ÷ logical size snapped to the 1/120 grid, and `unknown_q8 = 0` means "cannot be known", never a scale of zero. Never pair `logicalWidth()` with a division by `OutputInfo.scale` — one is exact and the other is not its inverse.
- **CommandList + Quad Renderer** (otter-render): All apps buffer draw commands via `DefaultCommandList` (solidRect, blendRect, roundedSolidRect, roundedBlendRect, roundedRectOutline, text, image, sprite, scissorPush/Pop, etc.), then `quad_renderer.rasterize()` plays them back with scissor clipping and damage culling. Text measurement: `font.measureTextAtScale(text, size, cmds.scale)`.
- **Terminal Rendering Boundary** (otter-vte): Terminal views use `DynamicCommandList`, `PowerlineOps`, `BlockOps`, `cell_glyphs`, and `CellRenderer(...)` from `otter-vte`. Apps provide terminal/session state and comptime hooks, while terminal cell rendering stays in the shared package so other apps can embed terminal output without copying `otter-term` internals.
- **Terminal Scroll Blit** (otter-term): `app/damage.zig` detects a uniform upward row shift between the SHM buffer's visual-hash snapshot and the current grid (`detectRowShift`, FNV row summaries, majority + k=0-dominance thresholds), memmoves the already-rendered pixel band (`Surface.blitRowsVertical`), rotates the snapshot rows, then lets the normal hash diff drive small render damage. A wrong shift only costs performance, never correctness, because the diff runs against the rotated snapshot. The moved band is submit-only damage (`TermApp.blit_submit_band`/`_prev`, reported for two frames) and never enters the render-culling set. Blit is gated off while overlays that bypass visual hashes are active (url underline, context menu, preedit, bell flash, kitty) plus a cooldown, and only engages when every viewport row was walked.
- **Terminal Scrollback Compression** (otter-term): `app/compression.zig` caches each ghostty-vt activity token, waits 250 ms after terminal activity, then schedules one incremental compression step per event-loop pass until the API reports complete or unsupported. Scheduler state follows each tab/split; logical scrollback content and limits remain unchanged.
- **Terminal ghostty boundary** (otter-term): the ghostty `ghostty-vt` **Zig module** (vendored package pin in `zig-pkg/`, imported as `ghostty_vt`; no C ABI, no installed libghostty-vt) owns paste sanitizing, word/line selection semantics and tracked active selections, OSC 7/9/1337 PWD parsing, OSC 8 hyperlinks, Unicode grapheme widths, cursor visuals, palette generation, and terminal protocol reports/callbacks (focus, resize, color scheme, device attributes, XTVERSION, clipboard writes). `TerminalCore` owns a `vt.Terminal` + comptime-specialized `vt.TerminalStream` (dispatch inlines; app callbacks attach via effect trampolines) + `vt.RenderState`; the render walk reads `RenderState.row_data` MultiArrayList slices directly. Executables importing `ghostty_vt` need `.use_llvm = true` (uucode tables crash the Zig 0.16 self-hosted x86_64 backend), and `src/fast_memset.zig` must stay pure inline-asm (a scalar loop gets loop-idiom-recognized back into a self-recursive `memset` call). Otter supplies Wayland policy/UI and sources terminal colors from `otter-term.conf`; UI chrome uses `otter-theme` tokens.
- **Text System Boundary** (otter-render): `src/text.zig` owns the backend boundary for HarfBuzz shaping, itijah bidi checks/layout, and Fontconfig translate-C. `TextSystem.measure` preserves the current FreeType fast path for ASCII/simple LTR and uses HarfBuzz advances plus itijah layout for complex text. `TextSystem.draw` renders shaped glyph IDs through cached FreeType glyph-index rasterization and routes `.notdef` clusters back through the existing fallback chain. `itijah` is vendored at latest main commit `a8a70fc73ea7bcfcffd260e390521c521c1e8490` with a Zig 0.16 build wrapper.
- **Border Radius** (otter-render/otter-theme): SDF-based rounded rect rendering via `sdf.zig`. Theme tokens: `popup.border_radius`, `spacing.widget_border_radius`, `spacing.button_border_radius`, `decorations.border_radius`. CommandList: `roundedSolidRect`, `roundedBlendRect`, `roundedRectOutline` with `corners: u4` bitmask (bit0=TL, bit1=TR, bit2=BL, bit3=BR). Zero-radius fast-paths to existing sharp rect logic. Compositor border radius sent via `set_borders` protocol request with `radius` argument.
- **Damage Tracking** (otter-wayland): `DamageTracker` accumulates dirty rects with double-buffer support. Falls back to full redraw on overflow.
- **UI command storage** (otter-ui): `Capacities.command_storage = false` is only for input/layout states whose application owns an external command list. Rendering entry points intentionally fail at compile time for those states. Rendering apps keep the default bounded command capacity unless measured frame maxima and overflow behavior prove a smaller capacity safe.
- **Monitor storage and aggregation** (otter-desktop/otter-monitor): Process, previous-process, desktop catalog, and visible/sort storage retain dynamic capacity proportional to observed counts. Application aggregation uses the sorted PID index and compact desktop catalog indices; do not restore fixed maximum-sized tables or per-process desktop strings.
- **Search index lifecycle** (otter-tools-core/otter-search): File-index arrays grow geometrically within the configured memory budget; paths use one owned allocation per entry with relative/name aliases. Content trigram signatures are learned lazily from real queries, so startup does not read every indexed file. Content workers read the live index only while mutations are excluded; cancel and join them before watcher updates or index replacement. Inotify updates are incremental, with full rebuild reserved for queue overflow or watch invalidation.
- **Animation** (otter-render): Integer-only ease-out quadratic. `anim.tick(expanding)` advances, `anim.lerp(from, to)` interpolates. Handles mid-animation reversal.
- **Pub/Sub** (otter-wayland): `SubscriberList` for workspace, toplevel, and SysInfo state changes.
- **Keyboard/IME** (otter-wayland): `Keyboard` wraps xkbcommon with callbacks + timerfd repeat. `TextInput` wraps zwp_text_input_v3 for CJK/compose — check `isComposing()` to suppress direct key handling.
- **Drawing Primitives** (otter-ui): `drawing.zig` is a re-export barrel over `otter-ui/src/drawing/` (`core`, `text`, `frame`, `input`, `controls`, `select`, `dropdown`, `color_picker`). Roughly 60 stateless helpers with no coupling to app config structs: border, inputBox, wrappingInputBox, toggle, checkbox, colorSwatch, dropdown, dropdownOverlay, tabBar, scrollbar, formRow, sectionHeader, button, numberInput, progressBar, iconButton, textTruncated, wrappedText, colorPickerPopup, passwordInputBox, authStatusLine, maskUtf8, etc.
- **ScrollState** (otter-ui): Vertical scroll tracking with `scroll(delta)`, `needsScrollbar()`, `thumbRect()`, `maxOffset()`.
- **Theme Presets** (otter-theme): 12 comptime themes in `presets.zig` (Otter Shell, Otter Shell Islands, Catppuccin Mocha/Latte/Frappe/Macchiato, Nord, Gruvbox Dark, Gruvbox Light, Dracula, Tokyo Night, One Dark). `findPreset(name)` for lookup, `all_presets` for iteration.
- **Universal Theming**: Widget configs use `?Color = null` for theme-mapped fields, resolved via `config.field orelse theme.token` in root_container. Precedence: widget config > theme.conf > compiled-in defaults.
- **Config Normalization**: On startup, apps parse and re-save configs (strips unknown fields, adds missing defaults). Bar custom buttons use `otter-conf.Dynamic` indexed fields (`button_N_name`, `button_N_enabled`, `button_N_font_icon`, `button_N_command`, etc.) and appear in layouts as `button_<name>`. Legacy `button_<name>_*` fields are migrated to the indexed form. Optional fields (`?Color`, `?u16`) are NOT emitted. Only writes to `~/.config/otter-shell/`, never system configs.
- **Clipboard / DnD** (otter-wayland): `Clipboard` struct wraps `wl_data_device` for paste and drag-and-drop support. `getText()` creates a pipe, calls `offer.receive("text/plain;charset=utf-8", fd)`, polls with timeout, reads result. DnD accepts `text/uri-list` and text MIME offers, converts file URIs to shell-escaped paths, and invokes the registered drop callback. Used by otter-settings for Ctrl+V and otter-term for drop-to-paste.
- **ConfigDoc** (otter-settings): Preserves comments, field order, and custom fields through edits. `serialize()` writes directly to disk without round-tripping through typed parser. `removeFieldsWithPrefix()` for bulk field deletion, `removeFromLayouts()` for layout cleanup (trims spaced names so widgets such as `dnd` return to the General layout + picker). `tabs.zig` registers one sidebar tab per app config file (including `otter-dock.conf` and `otter-taskbar.conf`). Bar layout chips list builtins from `editor_widgets.available_widgets` (`dnd`, `nightlight` included).
- **Theme Loading** (otter-theme): `loader.loadTheme(allocator)` reads `theme.conf` with fallback chain (user → system → compiled defaults) and **does not write** the file. `normalizeThemeConfig` re-saves user `theme.conf` only when serialized output differs — **only otter-settings** (once at startup before the theme watcher runs) and **otter-theme-gen** should call it; hot reload paths must use `loadTheme` only or inotify loops. Other apps only watch `theme.conf` via inotify. `getThemeConfigPath()` and `getSystemThemePath()` provide standard path construction for watchers.
- **Sized Image Decode** (zigimg/otter-render): `Image.loadFromFileSampled` uses bounded JPEG/PNG statistical sampling for theme extraction. Render-facing `loadFromFileAtSize` / `loadFromMemoryAtSize` preserve aspect ratio and use alpha-aware box filtering for every registered format, decoding the source once without the former second full-size RGBA staging copy. NanoSVG resolves `currentColor` while parsing instead of copying and rewriting SVG text.
- **Hot-Reload**: `otter-conf.Watcher.watchConfigPath` watches the parent directory (atomic rename from otter-settings does not kill the watch). Event loops call `drainChanged()` then reload **once**. `IN_IGNORED` is not a change, so watch refresh cannot loop. Theme uses `ThemeWatcher` with the same drain. Bar, notifications, wallpaper, OSD, and idle poll watcher FDs for app config and theme.
- **Wallpaper State File**: `otter-wallpaper` writes `$XDG_RUNTIME_DIR/otter-shell/wallpaper-state` (legacy `/tmp/{uid}/otter-wallpaper-state` still read when present) with `output_name=wallpaper_path` lines on every wallpaper change and removes it on normal exit or catchable shutdown signals. Path construction lives in `otter-utils/src/runtime_state.zig`. Used by lockscreen/greeter/shot/theme-gen to display or consume matching wallpapers while wallpaper is running. `same_on_all_displays` defaults to true so all non-override outputs show the same image.
- **Wallpaper SHM and catalog lifetime**: Each wallpaper surface keeps one single-buffer SHM pool in steady state. Never force-release or rewrite a compositor-owned buffer: allocate a replacement, retire the old pool until `wl_buffer.release`, then reclaim it after dispatch. Folder image lists store compact path references into one byte blob rather than fixed 4 KiB path slots.
- **D-Bus** (otter-desktop): UPower, PowerProfiles, MPRIS, SystemTray, NetworkManager, SCX Loader, Screensaver, ScreenSaverService, Logind, Notifications, Polkit Agent, Fprintd, GNOME DisplayConfig, switcheroo-control. All use sd-bus (vendored basu). **Important**: `sd_bus_process()` handles one message per call — must loop to drain.
- **XDG Desktop Portal** (`xdg-desktop-portal-otter`): Otter-only backend for `xdg-desktop-portal`. It advertises all 21 impl interfaces in `otter.portal` so no foreign backend can claim them, validates every call against its contract, and answers only what Otter owns: native Settings reads and watches the shared `otter-theme` graph; native Wallpaper calls `otter-wallpaper --set`, so the daemon's watched config remains the only wallpaper state writer and preview or lockscreen-only requests return failure; representable FileChooser `OpenFile`/`SaveFile`/`SaveFiles` requests use the `otter-files` OTFP v1 socket bridge with one bounded connect, one coalesced spawn, and one retry; Notification maps to `org.freedesktop.Notifications` directly; Screenshot spawns `otter-screenshot --fullscreen --output` (PickColor and interactive stay fail-closed); idle-only Inhibit maps to `org.freedesktop.ScreenSaver`; ScreenCast CreateSession/SelectSources/Start exports a PipeWire Video/Source fed by Wayland Capturer (pattern BGRx fallback without a display); RemoteDesktop CreateSession/SelectDevices/Start/ConnectToEIS uses system libeis with virtual-pointer/keyboard inject and Notify* until EIS connects. Every other advertised method, property, and unrepresentable FileChooser request fails closed with `org.freedesktop.portal.Error.Failed`; nothing forwards to GTK, GNOME, KDE, Hyprland, or keyring portals. Request and Session handles are caller-scoped and cancelled on `Close`, caller disconnect, or frontend disconnect.
- **GNOME DisplayConfig** (otter-desktop): read-only wrapper over `org.gnome.Mutter.DisplayConfig.GetCurrentState`, which is the only published source of a GNOME desktop's **fractional** per-monitor scale — `wl_output.scale` is an integer by protocol and everything else reconstructs the factor from geometry. `ApplyMonitorsConfig` is deliberately not wrapped: nothing in this shell should be able to reconfigure a user's displays. The reply signatures are pinned in the file and were read out of the installed `libmutter-17.so.0.0.0` rather than transcribed. The walk is duck-typed over the message reader so it can be tested with no session bus (`sd_bus_message_new` refuses a bus that has not completed an auth handshake, so a real reply cannot be constructed offline). `org.gnome.Shell.Introspect.GetWindows` is **not** wrapped: the interface XML gnome-shell ships documents its keys exhaustively and carries no monitor index, position or pid, so it cannot associate a window with an output.
- **Icon Lookup** (otter-desktop): Scans actual directories (preferred themes first, then all themes, pixmaps fallback, desktop file fallback). SVG preferred over raster. Works with any theme layout.
- **Global Shared Services** (otter-bar): SysInfo and PipeWire are lazily heap-allocated singletons. Clock timezone loaded once via zeit with global minute tracking.

## Important Source Files

| Purpose | Location |
|---------|----------|
| Config parser | `otter-conf/src/parser.zig` |
| Config imports / dynamic fields | `otter-conf/src/import.zig`, `otter-conf/src/dynamic.zig` |
| Theme definitions | `otter-theme/src/theme.zig` |
| Theme presets | `otter-theme/src/presets.zig` |
| Bar widget shell | `otter-ui/src/widget.zig` |
| Surface Description frame | `otter-ui/src/ui_frame.zig` |
| Drawing primitives | `otter-ui/src/drawing.zig` (barrel) + `otter-ui/src/drawing/*.zig` |
| Input buffer | `otter-ui/src/input_buffer.zig` |
| Global `std.Io` singleton | `otter-utils/src/io.zig` |
| Runtime state paths | `otter-utils/src/runtime_state.zig` |
| Command list | `otter-render/src/command_list.zig` |
| Terminal rendering primitives | `otter-vte/src/command_list.zig`, `otter-vte/src/cell_renderer.zig`, `otter-vte/src/cell_glyphs.zig`, `otter-vte/src/ops.zig` |
| Quad renderer | `otter-render/src/quad_renderer.zig` |
| Sprite sheets | `otter-render/src/sprite.zig` |
| Image loading and region drawing | `otter-render/src/image.zig` |
| SDF rendering | `otter-render/src/sdf.zig` |
| Font rendering | `otter-render/src/font.zig` |
| Text System boundary | `otter-render/src/text.zig`, `otter-render/src/fontconfig.h` |
| Wayland connection | `otter-wayland/src/connection.zig` |
| Wayland protocol XML | `otter-wayland/protocols/` (`stable/`, `staging/`, `unstable/`, `wlr/`, plus dwl-ipc, otter-tag, otter-river) |
| Capture selection overlay | `otter-wayland/src/selection_overlay.zig` (shared by otter-screenshot, otter-shot, otter-rec, otter-clicker) |
| Output tracking (the one `wl_output` list) | `otter-wayland/src/capture/output.zig` |
| Hyprland handle → address map | `otter-wayland/src/toplevel_map.zig` |
| Output scale arithmetic (q8, 1/120 grid, uniformity) | `otter-wayland/src/output_scale.zig` |
| Compositor blur regions | `otter-wayland/src/background_effect.zig` |
| Keyboard handler | `otter-wayland/src/keyboard.zig` |
| Clipboard | `otter-wayland/src/clipboard.zig` |
| Bar main event loop | `otter-bar/src/main.zig` |
| Bar SD layout engine | `otter-bar/src/components/bar_layout_engine.zig` |
| Bar input dispatch / popup input | `otter-bar/src/components/bar_input_dispatch.zig`, `otter-bar/src/components/bar_popup_input.zig` |
| Bar config schema | `otter-bar/src/config.zig` |
| Dock entry point | `otter-dock/src/main.zig` |
| Dock config | `otter-dock/src/config.zig` |
| Dock state manager | `otter-dock/src/dock.zig` |
| Dock rendering | `otter-dock/src/draw.zig` |
| Dock magnification | `otter-dock/src/magnification.zig` |
| Dock layer surfaces | `otter-dock/src/shell.zig` |
| Dock window list sync | `otter-dock/src/dock_sync.zig` |
| Dock hover previews | `otter-dock/src/thumbnail.zig`, `otter-dock/src/popup.zig` + `ext_image_copy_capture` / `ext_foreign_toplevel_list` (see `docs/superpowers/specs/2026-03-30-otter-dock-design.md`) |
| Dock theme resolution | `otter-theme/src/theme.zig` (`Theme.colors`, `Theme.layout`, `Theme.spacing`, and derived `dockBackground`/`dockBorder`) |
| Taskbar entry point | `otter-taskbar/src/main.zig` |
| Taskbar config | `otter-taskbar/src/config.zig` |
| Taskbar state and layout | `otter-taskbar/src/state.zig`, `otter-taskbar/src/layout.zig` |
| Taskbar rendering and shell | `otter-taskbar/src/draw.zig`, `otter-taskbar/src/shell.zig` |
| Taskbar Start panel | `otter-taskbar/src/start_menu.zig` |
| Taskbar hover previews | `otter-taskbar/src/preview.zig` + `ext_image_copy_capture` / `ext_foreign_toplevel_list` |
| Taskbar config types | `otter-config-types/src/taskbar.zig` |
| Taskbar settings | `otter-settings/src/tabs.zig`, `otter-settings/src/editor.zig` |
| Terminal app | `otter-term/build.zig` (Zig 0.16 app embedding the ghostty `ghostty-vt` Zig module; Otter owns Wayland/PTY/render frontend) |
| Terminal scrollback compression | `otter-term/src/app/compression.zig`, `otter-term/src/terminal/core.zig` |
| Transcribe daemon and CLI | `otter-transcribe/src/main.zig`, `otter-transcribe/src/ctl.zig`, `otter-transcribe/src/config.zig`, `otter-transcribe/src/indicator.zig` |
| Transcribe config types | `otter-config-types/src/transcribe.zig` |
| Launcher Surface Description migration | `otter-launcher/src/draw.zig` (`LauncherUiState`, `UniformList`, hit registry), `otter-launcher/src/extensions.zig` (fixed-buffer calc/emoji/clip rows backed by `otter-tools-core` and bounded cache reads). Right-click `PopupMenu` for `.desktop` Actions and switcheroo GPU pick. |
| Jade entry point | `otter-jade/src/main.zig` |
| Hypr layout+titlebar entry | `otter-hypr/src/main.zig`, `lua/otter_hypr_layout/init.lua` |
| Jade config/state/simulation | `otter-jade/src/config.zig`, `otter-jade/src/state.zig`, `otter-jade/src/sim.zig` |
| Jade drawing/input/sprites | `otter-jade/src/draw.zig`, `otter-jade/src/input.zig`, `otter-jade/src/sprites.zig` |
| WLR foreign toplevel | `otter-wayland/src/protocols/foreign_toplevel.zig` |
| Compositor-specific IPC | `otter-wayland/src/protocols/hyprland.zig`, `niri.zig`, `dwl_ipc.zig`, `otter_tag.zig`, `ext_workspace.zig` |
| Dock config types | `otter-config-types/src/dock.zig` |
| Widget container | `otter-bar/src/components/root_container.zig` |
| Theme loader | `otter-theme/src/loader.zig` |
| Settings entry point | `otter-settings/src/main.zig` |
| XDG desktop portal backend | `xdg-desktop-portal-otter/src/main.zig`, `xdg-desktop-portal-otter/src/broker.zig`, `xdg-desktop-portal-otter/src/native.zig`, `xdg-desktop-portal-otter/src/native_settings.zig`, `xdg-desktop-portal-otter/src/native_wallpaper.zig`, `xdg-desktop-portal-otter/src/native_notification.zig`, `xdg-desktop-portal-otter/src/native_screenshot.zig`, `xdg-desktop-portal-otter/src/native_inhibit.zig`, `xdg-desktop-portal-otter/src/native_screencast.zig`, `xdg-desktop-portal-otter/src/screencast_feed.zig`, `xdg-desktop-portal-otter/src/native_remotedesktop.zig`, `xdg-desktop-portal-otter/src/eis_server.zig`, `xdg-desktop-portal-otter/src/picker.zig` |
| Portal contracts, ownership, and routes | `xdg-desktop-portal-otter/src/contracts.zig`, `xdg-desktop-portal-otter/src/ownership.zig`, `xdg-desktop-portal-otter/src/routes.zig` |
| Portal integration tests and packaging | `xdg-desktop-portal-otter/tests/`, `xdg-desktop-portal-otter/data/` |
| Assistant app entry | `otter-assistant/src/main.zig` |
| Assistant daemon | `otter-assist/src/main.zig` |
| Search daemon | `otter-search/src/main.zig` |
| Screenshot tool | `otter-screenshot/src/main.zig` |
| System monitor | `otter-monitor/src/main.zig` |
| Otter HUD / Otter Bench suite | `otter-bench/` (`layers/`, `libs/`, `apps/`; see `otter-bench/CLAUDE.md`) |
| Settings app struct | `otter-settings/src/app.zig` |
| Settings input handlers | `otter-settings/src/input_handlers.zig` |
| Settings config editor | `otter-settings/src/editor.zig` |
| Settings draw context | `otter-settings/src/draw.zig` |
| Settings form rendering | `otter-settings/src/draw_form.zig` |
| Settings chip rendering | `otter-settings/src/draw_chips.zig` |
| Settings theme browser | `otter-settings/src/theme_browser.zig` |
| Settings theme fields | `otter-settings/src/theme_fields.zig` |
| Theme Gen daemon / one-shot CLI | `otter-theme-gen/src/main.zig`, `otter-theme-gen/src/cli.zig` |
| Theme Gen config | `otter-theme-gen/src/config.zig` |
| Theme Gen palette | `otter-theme-gen/src/palette.zig` (re-export of `otter-tools-core/src/theme_palette.zig`) |
| Theme Gen template | `otter-theme-gen/src/template.zig` |
| Theme Gen SplatHash | `otter-theme-gen/src/splathash.zig` (re-export of `otter-tools-core/src/splathash.zig`) |
| Small tools shared core | `otter-tools-core/src/root.zig`, `otter-tools-core/src/clip_history.zig`, `otter-tools-core/src/record.zig`, `otter-tools-core/src/color.zig`, `otter-tools-core/src/splathash.zig`, `otter-tools-core/src/theme_palette.zig`, `otter-tools-core/src/calendar.zig`, `otter-tools-core/src/emoji.zig`, `otter-tools-core/src/duration.zig`, `otter-tools-core/src/weather.zig`, `otter-tools-core/src/calc.zig`, `otter-tools-core/src/assist_client.zig`, `otter-tools-core/src/knowledge.zig`, `otter-tools-core/src/web_search.zig`, `otter-tools-core/src/nightlight.zig` |
| Clipboard manager | `otter-clip/src/main.zig`, `otter-clip/src/copy.zig`, `otter-clip/src/paste.zig` |
| Screen recorder | `otter-rec/src/main.zig`, `otter-rec/src/portal_recorder.zig` (portal PipeWire stream capture) |
| Color picker | `otter-pick/src/main.zig` |
| Calendar popover | `otter-cal/src/main.zig` |
| Emoji picker | `otter-emoji/src/main.zig` |
| Timer | `otter-timer/src/main.zig` |
| Sticky notes | `otter-note/src/main.zig` |
| Weather helper | `otter-weather/src/main.zig` |
| Weather bar widget | `otter-ui/src/widgets/weather.zig` |
| Calculator | `otter-calc/src/main.zig` |
| Voice TTS CLI | `otter-vox/src/main.zig`, `otter-vox/src/model.zig`, `otter-vox/src/runtime.zig` (embedded Kokoro GGUF + static espeak-ng data, materializes to `$XDG_RUNTIME_DIR`) |
| Auto clicker | `otter-clicker/src/main.zig`, `otter-clicker/src/virtual_pointer.zig`, `otter-clicker/src/uinput.zig` (shared point overlay + Wayland virtual-pointer injection with uinput fallback) |
| PipeWire one-shot playback | `otter-desktop/src/pipewire_playback.zig` |
| Interaction cues | `otter-cue/src/root.zig`, `otter-cue/src/recipe.zig`, `otter-cue/src/engine.zig`, `otter-cue/src/bind.zig`, `otter-cue/src/playback.zig` |
| Config type definitions | `otter-config-types/src/root.zig` |
| Polkit agent entry | `otter-polkit/src/main.zig` |
| Overview overlay | `otter-overview/src/main.zig`, `otter-overview/src/layout.zig`, `otter-overview/src/hypr.zig`, `otter-wayland/src/protocols/niri.zig` (Hypr 0.56 export skips windows that miss the monitor; overflow columns use a temporary scrolling-tape nudge, not a window swap; bottom strip click-scrolls the matching workspace card and paints mini window tiles, centered on the card strip; Ctrl+1..9 / Ctrl+0 jump the same indices without feeding digits into search). Mapped overlay 1:1 3-finger swipe via `zwp_pointer_gestures_v1`. Optional Hyprland 0.55+ lua `otter_hypr_layout.overview_gesture.install()` is compositor bind for *opening* from the desktop |
| Lock entry point | `otter-lock/src/main.zig` |
| Lock config | `otter-lock/src/config.zig` |
| Lock drawing | `otter-lock/src/draw.zig` |
| Greeter daemon | `otter-greeter/src/main_daemon.zig`, `otter-greeter/src/daemon.zig`, `otter-greeter/src/seat.zig` |
| Greeter UI | `otter-greeter/src/main_ui.zig`, `otter-greeter/src/ui_app.zig`, `otter-greeter/src/ui_draw.zig` |
| Greeter IPC | `otter-greeter/src/ipc.zig` |
| Idle entry point | `otter-idle/src/main.zig` |
| Idle config | `otter-idle/src/config.zig` |
| Idle DPMS control | `otter-idle/src/dpms.zig` |
| Night Light daemon | `otter-nightlight/src/main.zig` |
| Gamma control | `otter-wayland/src/gamma.zig` |
| Shot app | `otter-shot/src/main.zig`, `otter-shot/src/app.zig`, `otter-shot/src/state.zig` |
| Shot composition/export | `otter-shot/src/compose/shot_composer.zig`, `otter-shot/src/compose/screenshot_gradients.zig`, `otter-shot/src/export/file.zig`, `otter-shot/src/export/clipboard.zig` |
| Shot capture/UI | `otter-shot/src/capture/workflow.zig`, `otter-wayland/src/selection_overlay.zig`, `otter-shot/src/ui/draw.zig`, `otter-shot/src/ui/inspector.zig` |
| Logind D-Bus client | `otter-desktop/src/logind.zig` |
| ScreenSaver service | `otter-desktop/src/screensaver_service.zig` |
| Polkit D-Bus agent | `otter-desktop/src/polkit_agent.zig` |
| PAM authentication | `otter-desktop/src/pam.zig` |
| Fprintd D-Bus client | `otter-desktop/src/fprintd.zig` |
| GNOME/Mutter display config client | `otter-desktop/src/gnome_display_config.zig` |
| switcheroo-control GPU list | `otter-desktop/src/switcheroo.zig` |

Each app follows the pattern: `<app>/src/main.zig` (entry), `config.zig` (schema), `draw.zig` (renderer).

## Vendored Dependencies

- **basu** (`otter-desktop/vendor/basu/`): Standalone sd-bus from systemd. No runtime libsystemd dependency.
- **PipeWire** (`otter-desktop/vendor/pipewire/`, from `allyourcodebase/pipewire`): Zig bindings with dlopen shims. Statically linked.
- **itijah** (`otter-render/vendor/itijah/`): Zig-native Unicode Bidirectional Algorithm, vendored from latest main with a local Zig 0.16 build wrapper.

## Configuration Format (otter-conf)

Flat key-value format with `#` comments. Nested struct flattening: `clock_text_color` maps to `config.clock.text_color`. All config struct fields must have defaults. Supported types: booleans, integers, floats, strings, enums, arrays, slices, optionals, custom parse/toStr types, nested structs. Unknown fields silently skipped. `Dynamic(T, prefix)` indexed entries are capped at indices `0..4095` (`parser_support.max_dynamic_entries`); import nesting is capped at depth 128 (`import.max_import_depth`) and total merged output is capped by `LoadOptions.max_file_size`.

Widget configs use `?Color = null` for theme-mapped fields. Resolved at widget init: `config.field orelse theme.token`. Serializer omits null fields, keeping configs minimal.

### Theme Configuration

Config: `~/.config/otter-shell/theme.conf` (fallback: `/etc/otter-shell/`, then compiled-in defaults). Hot-reloadable via inotify. Uses same flat key-value format: `colors_background`, `popup_padding`, `bar_height`, `spacing_widget_padding`, `fonts_font_family`, etc. `font_family` controls default font; per-app `font_path` overrides it.

### Visual profiles and verification

Theme resolution is low to high: compiled-in Current fallback → selected profile (`current.conf` or all-dark `bank.conf`) → optional `generated-colors.conf` → root `theme.conf` overrides → per-app/per-widget overrides. Apps consume semantic style metrics; they do not branch on profile names. `generated-colors.conf` is colour-only, written atomically by `otter-theme-gen`, and cannot change profile geometry, density, typography, radii, or layout. Settings controls whether its import is enabled.

Current is a dark continuous-plane system with one 4 px radius on standalone app controls, rows, panels, popups, decorations, and dock slots; only true joined edges are square. Its compact Bar has a feature/anatomy compatibility contract, not a pixel freeze: visual tokens may change its palette/radii, but preserve the rounded active workspace chip, real SVG/font icons, live widget content, dense packing, centered title, and lack of invented workspace/title indicators. Current's 2 px line is reserved for focus, status, and progress surfaces. Bank is warm mineral and all-dark: opaque dark planes, with square markers and short baselines reserved for status, workspace, and progress; it must not introduce light panels, split light/dark surfaces, or required blur. Generic navigation/list selection uses tonal fill only in both profiles. Both profiles use CPU-renderable fills, lines, and rounded rectangles. A selected or focused control uses one thin outline/focus ring or one line/marker, never both.

Long-running apps use `ThemeWatcher`, watching `theme.conf`, the selected profile, generated colours, and every imported path. A reload parse/import failure retains the previous valid theme and logs the error; it must not publish partial/default state or rewrite files. `loadTheme` is read-only; normalization/writes belong to Settings and Theme Gen.

Path helpers honour `XDG_CONFIG_HOME`. Tests and visual captures set it to a temporary directory, so they neither read nor write the developer's session configuration. Never capture the real Wayland session: use isolated headless Sway/Grim or a direct-render fixture when a protocol is unavailable.

Shared fixture and comparison commands:

```bash
cd otter-ui
zig build -Doptimize=ReleaseFast visual-fixture -- --profile current --case default --scale 1 --out zig-out/visual/current-default@1x.png
zig build -Doptimize=ReleaseFast visual-compare -- --expected testdata/visual/current/default@1x.png --actual zig-out/visual/current-default@1x.png --diff zig-out/visual/current-default.diff.png
tools/headless-capture.sh --profile bank --out zig-out/visual/bank-headless.png -- <app> <args>
```

`ReleaseFast` is required for build, test, fixture, compare, and benchmark evidence; Debug runs do not count.

## Wayland Protocols

Protocol XML lives under `otter-wayland/protocols/`:

- **stable**: xdg-shell, viewporter, tablet
- **staging**: alpha-modifier, content-type, cursor-shape, ext-background-effect, ext-foreign-toplevel-list, ext-idle-notify, ext-image-capture-source, ext-image-copy-capture, ext-session-lock, ext-workspace, single-pixel-buffer, tearing-control, xdg-activation, xdg-toplevel-tag
- **unstable**: idle-inhibit, linux-dmabuf, pointer-constraints, text-input, xdg-decoration, xdg-foreign, xdg-output
- **wlr**: layer-shell, foreign-toplevel-management, output-power-management, virtual-pointer, etc.
- **compositor-specific**: `dwl-ipc-unstable-v2`, `hyprland-toplevel-mapping-v1` (ext/wlr handle → 64-bit Hypr address), `otter-tag-v1`, and the `otter-river-*` families (window/input/libinput/xkb management, layer shell)

**Output scale** (`otter-wayland/src/output_scale.zig`) reads each output's real
scale factor from core `wl_output` plus `xdg-output`, both of which wlroots, KWin
and Mutter all implement — so no new protocol is required. The integer
`wl_output.scale` is a ceiling and reports 2 for a 150% display; the honest
factor is `mode / xdg_output logical_size`, snapped to the 1/120 grid. Unknown is
reported as zero rather than guessed. `wp-fractional-scale-v1` is deliberately
**not** vendored: it is surface-scoped, so a process with no window cannot query
it. `ForeignToplevelManager.outputForAppId` associates a client with an output
where the scales differ, and reports `ambiguous` rather than picking one.

`BackgroundEffect` owns compositor blur regions for translucent surfaces. `XdgToplevel` wrapper provides reusable toplevel window lifecycle with configure handling and HiDPI scale tracking.

## C Dependencies

**Dynamic**: Fontconfig, wayland-client, xkbcommon, PAM (optional). **Zig-packaged/static**: FreeType (`allyourcodebase/freetype`), HarfBuzz (`allyourcodebase/harfbuzz`). **Vendored**: basu (sd-bus), PipeWire, itijah. **Pure Zig**: zigimg (raster image formats), zeit (timezone/date).

## Widgets (otter-ui/src/widgets/)

All bar widgets embed a `Widget` shell for geometry/motion state and implement struct methods for draw/input. Key widgets:
- **clock** - Time display via zeit, left-click calendar popover (stays until click-off), global minute tracking
- **workspaces** - Workspace indicator/switcher via ext-workspace protocol
- **battery** - UPower D-Bus; click menu lists batteries plus power profiles; auto-hides when no battery
- **brightness** - Sysfs panel + keyboard LED + optional ddcutil DDC; click menu, scroll primary
- **active_window** - Focused window title via foreign_toplevel
- **button** - Clickable icon button with command execution
- **power_profiles** - Power profile selector via D-Bus
- **cpu_load/cpu_temp/memory** - System metrics via SysInfo with threshold colors; cpu_temp click lists CPU/GPU hwmon sensors
- **network** - NetworkManager D-Bus with WiFi, OpenVPN/WireGuard VPN, and Wi-Fi password prompt
- **weather** - Cached Open-Meteo current temperature with 7-day popup text
- **volume** - PipeWire audio control with per-device popup
- **falcond** - Daemon status via inotify
- **mpris** - Media player via MPRIS D-Bus
- **system_tray** - StatusNotifierItem icons with animated expand/collapse, DBusMenu context menus
- **dnd** - Shared runtime Do Not Disturb state toggle with bell/bell-off SVG status icons
- **nightlight** - Night Light toggle; left-click `otter-nightlight`, right-click Kelvin/schedule/suspend menu

## Logging (otter-utils)

```zig
const log = otter_log.Scoped("component-name");
log.info("message", .{});
var counter = otter_log.Counter{};  // Performance counters
var reporter = otter_log.Reporter("otter-bar", 30).init();  // Periodic reporters
```

## Memory Management

- **Daemons / long-running apps** (bar, notifications, osd, wallpaper, polkit, settings, idle, overview): `std.heap.smp_allocator` in release builds, `std.heap.DebugAllocator` in Debug (leak checking). Apps pick between them in a small `allocator()` helper in `main.zig`.
- **One-shot apps** (launcher, logout): `ArenaAllocator` backed by `page_allocator` for bulk cleanup on exit.
- **BoundedArray** for stack-allocated fixed-capacity collections throughout.
- **IconImageCache**: `IconImageCache(N)` fixed-slot for bar, `DynamicIconImageCache` with LRU eviction for launcher. Negative caching for missing icons.
- **Font glyph cache**: Proactive culling at 8192 entries, reactive eviction on alloc failure. Fallback fonts from `/usr/share/fonts/otter-shell/` via mmap.
- `otter-wayland` calls `malloc_trim(0)` every ~300 dispatches to reclaim glibc heap from libwayland churn.

## Zig 0.16 API Notes

The repo is fully on Zig 0.16 — every `build.zig.zon` declares `.minimum_zig_version = "0.16.0"` and all 37 app entry points use the 0.16 `main` signature. The notes below describe the idioms the code actually uses; do not reintroduce the 0.15 forms.

### The `io` Parameter is Everywhere

Most blocking/system APIs take an `std.Io` as their first argument. `main` receives a `std.process.Init` which provides the `io`:

```zig
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    otter_utils.io.install(io);   // shared libraries read it back via otter_utils.io.get()
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    // ... no std.os.argv / std.os.environ globals
}
```

Library code in this repo does **not** thread `io` through its own signatures; it calls `otter_utils.io.get()`. Apps must call `install()` before any library I/O runs.

### ArrayList

`std.ArrayList` is unmanaged: it does not store an allocator, and the allocator is passed to each method. Initialize with `.empty`:

```zig
var buffer: std.ArrayListUnmanaged(u8) = .empty;
defer buffer.deinit(allocator);

try buffer.append(allocator, byte);
const slice = try buffer.toOwnedSlice(allocator);
```

As a struct field: `items: std.ArrayListUnmanaged(Item) = .empty,` with `deinit(self.allocator)` in the struct's `deinit`.

### File System

`std.fs.Dir` / `std.fs.File` are `std.Io.Dir` / `std.Io.File`, and all methods take `io`:

```zig
file.close(io);
const n = try file.readStreaming(io, buf);
const len = try file.length(io);
```

Names: `readStreaming` (not `read`), `writeStreaming` (not `write`), `readPositional` (not `pread`), `writePositional` (not `pwrite`), `length` (not `getEndPos`), `setLength` (not `setEndPos`). Absolute-path helpers are on the type: `std.Io.Dir.createFileAbsolute(io, path, .{})`, `std.Io.Dir.deleteFileAbsolute(io, path)`, `std.Io.Dir.realPathFile`.

### Reader/Writer

`GenericReader`, `AnyReader`, `FixedBufferStream`, `CountingReader`, and `Io.Writer.null_writer` do not exist. Use the concrete `std.Io.Writer` / `std.Io.Reader`:

```zig
const stdout = io.terminal.out;
try std.Io.Writer.print(stdout, "hello", .{});
```

Reading a whole file goes through a reader interface, e.g. `reader.interface.allocRemaining(allocator, .limited(max_file_size))`.

### Process Spawn

```zig
var child = try std.process.spawn(io, .{ .argv = argv, .stdin = .pipe });
```

Also: `std.process.replace(io, ...)` for exec, `std.process.openExecutable` for self-exe.

### Sync Primitives Live Under `std.Io`

| Old | Current |
|------|------|
| `std.Thread.Mutex` | `std.Io.Mutex` |
| `std.Thread.Condition` | `std.Io.Condition` |
| `std.Thread.ResetEvent` | `std.Io.Event` |
| `std.Thread.WaitGroup` | `std.Io.Group` |
| `std.Thread.Semaphore` | `std.Io.Semaphore` |
| `std.Thread.RwLock` | `std.Io.RwLock` |
| `std.Thread.Pool` | `std.Io.Group` |

All take `io` and support cancelation. `std.Thread.Pool` and `std.once` do not exist.

### Time

`std.time.Instant`, `std.time.Timer`, and `std.time.timestamp()` are gone. Use `std.Io.Clock`:

```zig
const now_ns = std.Io.Clock.awake.now(io).nanoseconds;  // i96
```

`otter-ui/src/widget.zig` wraps this in a small `Timer` struct that replaces the removed `std.time.Timer`.

### Allocators

- `std.heap.ArenaAllocator` is lock-free and thread-safe.
- `std.heap.ThreadSafeAllocator` does not exist — pick a lock-free allocator directly (`std.heap.smp_allocator`).
- `std.heap.GeneralPurposeAllocator` is now `std.heap.DebugAllocator`.

### Random / Entropy

```zig
io.random(&buf);          // may use cached state
io.randomSecure(&buf);    // always syscalls (for keys etc.)
```

### `@Type` Does Not Exist

Use the targeted builtins — relevant to the comptime parser code:

```zig
const T = @Int(.unsigned, 10);
```

Also: `@Struct`, `@Union`, `@Enum`, `@Tuple`, `@Pointer`, `@Fn`.

### Float ↔ Int Conversions

- Small integer types implicitly coerce to floats when all values fit.
- `@intFromFloat` is deprecated — `@floor`/`@ceil`/`@round`/`@trunc` return integers directly.

### Packed Type Restrictions (Impacts Our Wayland/D-Bus Bindings)

- `packed union` requires an explicit backing integer: `packed union(u16) { ... }`.
- No pointers in `packed struct` / `packed union`.
- All fields must fit the backing integer (no unused bits).
- Extern contexts require explicit backing types.

### Vector Runtime Indexing Forbidden

Round-trip through an array:

```zig
const info = @typeInfo(@TypeOf(vector)).vector;
const arr: [info.len]info.child = vector;
const val = arr[runtime_index];
```

### Format Names

- `std.fmt.Alt` (was `std.fmt.Formatter`)
- `std.fmt.Options` (was `std.fmt.FormatOptions`)
- `std.fmt.bufPrintSentinel` (was `std.fmt.bufPrintZ`)

### Error Set Names

| Old | Current |
|------|------|
| `error.RenameAcrossMountPoints` | `error.CrossDevice` |
| `error.NotSameFileSystem` | `error.CrossDevice` |
| `error.SharingViolation` | `error.FileBusy` |
| `error.EnvironmentVariableNotFound` | `error.EnvironmentVariableMissing` |

### C Interop: `b.addTranslateC`, not `@cImport`

C translation lives in the build system. Eleven packages wire a translate-c step: `otter-bench`, `otter-clicker`, `otter-desktop`, `otter-greeter`, `otter-rec`, `otter-render`, `otter-term`, `otter-theme-gen`, `otter-utils`, `otter-vox`, `otter-wayland`.

The only remaining `@cImport` call sites are in vendored third-party code (`otter-desktop/vendor/pipewire/`, `otter-render/vendor/itijah/src/test/diff_oracle.zig`) and in `zango`, which is a separate compositor project. **New first-party code must not use `@cImport`.**

Write a real `.h` file and wire the step in `build.zig`:

```c
// src/c.h
#include <xkbcommon/xkbcommon.h>
```

```zig
// build.zig
const translate_c = b.addTranslateC(.{
    .root_source_file = b.path("src/c.h"),
    .target = target,
    .optimize = optimize,
});
translate_c.linkSystemLibrary("xkbcommon", .{});

const exe = b.addExecutable(.{
    .name = "otter-foo",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "c", .module = translate_c.createModule() },
        },
    }),
});

// callsite
const c = @import("c");
```

For advanced knobs, depend on the `translate-c` package explicitly.

### Other Removals Worth Knowing

- `std.SegmentedList` — no replacement; build our own if needed.
- `fs.realpathZ`/`.W` variants → `std.Io.Dir.realPathFile`.
- Windows `DynLib` → call `LoadLibraryExW` directly.
- `builtin.subsystem` → `zig.Subsystem`.
