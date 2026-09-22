# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## RULES TO FOLLOW

Always write zig 0.16.0 not older zig
Always use release builds (`-Doptimize=ReleaseFast`) for build/test commands; Debug builds can segfault in large transitive compiles
Always update unit test, benchmarks, readme and this document when making changes that require it
Follow data drive design and branchless programming pattern wherever possible
Performance is critical, if something is going to hurt performance flag it up
Never add Co-Authored-By or any co-author lines to git commits

## Repository Overview

Otter Shell is a Zig-based Wayland desktop shell monorepo. The primary applications are `otter-bar` (status bar), `otter-launcher` (application launcher), `otter-files` (native file manager), `xdg-desktop-portal-otter` (XDG desktop portal backend), `otter-dock` (application dock with magnification and window previews), `otter-taskbar` (Windows-style taskbar with grouped windows, Start panel, and hover previews), `otter-term` (Ghostty-based terminal), `otter-monitor` (XDG toplevel system monitor), `otter-pkg` (graphical apt package manager), `otter-assistant` (AI assistant toplevel backed by `otter-assist`), `otter-assist` (local text-to-text assistant daemon on a per-Wayland-display Unix socket), `otter-notifications` (notification daemon), `otter-wallpaper` (wallpaper daemon), `otter-osd` (on-screen display daemon), `otter-transcribe` (hotkey transcription daemon with layer-shell indicator), `otter-jade` (animated layer-shell otter pet), `otter-logout` (power menu overlay), `otter-overview` (workspace/window overview plus the `otter-switcher` Alt-Tab executable), `otter-keybindhelp` (searchable compositor shortcut overlay), `otter-polkit` (polkit authentication agent), `otter-lock` (session lockscreen), `otter-greeter` (Wayland display manager daemon and greeter UI), `otter-idle` (idle management daemon), `otter-nightlight` (gamma night-light daemon), `otter-settings` (graphical config editor and theme browser), `otter-screenshot` (region screenshot tool over `ext_image_copy_capture_v1`), `otter-search` (desktop search daemon and `otter-searchctl` CLI), `otter-shot` (Wayland product-shot composer), `otter-theme-gen` (wallpaper-reactive theme generator daemon), `otter-hypr` (Hyprland `otter-float` lua layout + `otter-hypr-titlebar` companion), and `otter-bench` (Otter HUD + Otter Bench performance suite), all using the shared component libraries.
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

# Build and run file manager
cd otter-files && zig build -Doptimize=ReleaseFast run

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
| otter-theme | Four-layer visual theme (12 semantic colours, structural layout, complete spacing scale, globals, loader/migration) |
| otter-ui | Surface Description frame API (bounded layout, hit registry, overlays, UniformList), bar widget shell (geometry/motion state), drawing primitives, text input, icon caching, scroll state, VTE wrappers |
| otter-vte | Shared terminal rendering primitives: dynamic terminal command list, powerline/block glyph ops, custom cell glyphs, generic cell renderer for embeddable terminal views |
| otter-wayland | Wayland client (layer shell, xdg_shell, session lock, workspaces, toplevel, keyboard, IME, pointer, clipboard, damage tracking, capture selection overlay) |
| otter-config-types | Shared config struct definitions for all apps (bar, launcher, dock, taskbar, notifications, wallpaper, osd, transcribe, logout, overview, polkit, lock, idle) |
| otter-tools-core | Pure Zig bounded helpers for small tools: clipboard history, recorder encoder selection, color conversion, SplatHash sampling, semantic palette generation, calendar grids, emoji search, duration parsing, weather URL construction, calculator parsing, otter-search path/content indexing, assistant socket protocol helpers, vendored zidx knowledge retrieval, and Pika Search JSON parsing |
| otter-render | FreeType fonts, Text System boundary (HarfBuzz, itijah, Fontconfig), colors, image loading, sprite sheets, animation, CommandList + quad_renderer pipeline |
| otter-desktop | XDG icons, .desktop files, D-Bus services (UPower, MPRIS, SystemTray, NetworkManager, Logind, ScreenSaverService, etc.), SysInfo, PipeWire, PAM auth; `libotter_desktop.so.0` exports BASU-backed services to plugin hosts |
| otter-cue | Native Cuelume interaction-sound palette (17 synthesized cues, Bind hover/press/release/toggle, PipeWire playback via otter-desktop) |
| otter-geo | Pure geometry types (Point, Rect, Padding, Transform) |
| otter-utils | BoundedArray, logging, FilePath utilities, the app-wide `std.Io` singleton, runtime-state paths |

D-Bus (basu), PipeWire, and PAM are compile-time optional via `-Denable_dbus=false` / `-Denable_pipewire=false` / `-Denable_pam=false`. C allocator overridable with `-Dc_allocator=jemalloc` or `-Dc_allocator=mimalloc`.

## Key Design Patterns

- **Comptime Generic Parser** (otter-conf): `Parser(comptime T: type)` generates parsers at compile time. Nested struct flattening (`prefix_field` -> `config.prefix.field`), custom value types with `parse()`/`toStr()`, SIMD string scanning.
- **Global `std.Io`** (otter-utils): `otter_utils.io.install(io)` is called once from each app's `main` with the `std.Io` from `std.process.Init`; shared libraries read it back via `otter_utils.io.get()`. This keeps `io` out of library signatures while still routing I/O through the app's real `Io`. `get()` falls back to `std.Options.debug_io` when `install` has not run, so tests and one-off tools work unchanged.
- **Bar Widget Shell** (otter-ui): Bar widgets embed a `Widget` struct for shared geometry (`area`) and pointer state (`last_motion`, `full_redraw`). Layout, draw, and input call widget struct methods directly via `widget_registry` and Surface Description specs — no vtable.
- **Bar widget specs** (otter-ui): All 18 bar widgets emit frames via `otter-ui/src/widgets/specs/*.zig`; widget files own state and `drawFrame` emitters. `FieldRegistry` calls struct `getWidth`/`setArea`/`deinit` directly (child `Widget` shells hold area/motion only).
- **Bar layout** (otter-bar): `bar_layout_engine.zig` divides the bar into three fixed columns (each up to one third of inner width). Left packs LTR, center centers its group in the middle third, right packs RTL. `root_layout.zig` draws widgets and emits declarative SD rows for hits.
- **Keyboard layout and app ordering**: The bar's `keyboard_layout` widget uses native Niri/Hyprland state, falling back to effective XKB groups from Wayland modifiers elsewhere without taking focus. `keyboard_layout_notify_on_change` shows an OSD only after an initial layout is known. `system_tray_always_show` removes the tray toggle. Dock/taskbar `sort_running_by_position` sorts only the unpinned suffix by first tiled window, preserves unknown-order ties, and defers during pointer/keyboard interaction. Shared native queries have bounded replies, nonblocking reads, a 250 ms deadline, and a 500 ms minimum interval while enabled.
- **Bar input**: `bar_input_dispatch.zig` routes bar-surface pointer/scroll/click through `UiState.dispatch` plus hover-tooltip handling. Click popups (calendar, weather, volume, mpris, menus) stay until bar click or click-off overlay. `bar_popup_input.zig` handles LayerPopup surfaces.
- **Dim overlay teardown** (otter-wayland): Destroy the layer role and surface before the buffer-release roundtrip. Null-buffer unmapping leaves configure callbacks alive after their serials are invalidated, disconnecting clients on Mango. `OTTER_TEST_WAYLAND=1` enables the real-compositor lifecycle regression in the ReleaseFast test suite.
- **Capture selection overlay** (otter-wayland): `selection_overlay.zig` is the single shared frozen/live region selector for `otter-screenshot`, `otter-shot`, and `otter-rec`, and point selector for `otter-clicker`. Uses `capture_overlay` + direct SHM pixel compositing — **not** Surface Description. Interactive selection/editor surfaces are double-buffered and coalesce missed redraws until compositor buffer release; never rewrite compositor-owned buffers. Apps pass `selection_overlay.preset.{screenshot,shot,rec,clicker}` for layer namespace and visual mode (`.frozen_unshaded` for screenshot CLI, `.frozen_dimmed` for shot/rec, transparent `.live` for clicker).
- **Capture backend selection** (otter-wayland): Full-output capture prefers EXT image-copy capture plus an EXT output source, falling back to WLR screencopy v1–v3. Both raw paths normalize output transforms without changing packed pixel formats; WLR additionally handles `y_invert` and row padding. Use immediate WLR copies for bounded requests on static desktops. DMA-BUF registry binding caps the advertised version at v4 and consumes legacy v3 format/modifier events. Test both capture paths and DMA-BUF v3/v4 negotiation in isolated VMs.
- **File-picker windows** (otter-files): Only `--picker-service` owns the picker socket. Dedicated picker windows close after the last completed/cancelled/disconnected request, while validation errors keep active requests open. New directories default to directory permissions, including traversal, while files retain file permissions. `expand_places` controls initial Places expansion and is exposed in Settings. Ordinary windows retain FileManager1 ownership and are not reused as portal pickers. Portal spawn coalescing resets after the final request completes. Socket cleanup compares the pathname inode/device recorded after bind; a Unix socket FD has a different identity. Picker filename filters support bounded glob matching with bracket classes (including Firefox/LibreWolf `*.[zZ][iI][pP]` filters). Folder requests with both `directory=true` and `multiple=true` use the appended OTFP `open_directories` mode; keep existing wire mode numbers stable. Watcher refreshes retain visible contents, coalesce changes during scans, and ignore hidden-entry changes when hidden files are off. Refresh file contents on writer close, retain watches for unchanged paths, and defer watcher refreshes during operations so a copy cannot cancel itself. Sidebar mount completion opens the UDisks-returned path; discovery and repeated clicks must preserve outstanding device actions. Navigation still invalidates picker acceptance. Picker initial folders do not constrain later navigation: accept only the completed current listing generation. Reserve the picker footer in both rendering and view materialization. Surface Description clips descendant hit regions together with their visual viewport.
- **Screenshot color handling**: `otter-screenshot` and `otter-shot` share `otter-wayland.capture.Capturer`. `captureAll` queries active output descriptions through `wp_color_manager_v1` and normalizes supported PQ HDR outputs before stitching/cropping/annotation: preserve source precision, decode ST 2084, convert primaries, apply a BT.2390 shoulder from measured frame peak, and encode sRGB. Bit depth and EDID capability are not HDR detection. Toplevel captures and raw recording frames retain their compositor paths; Hyprland output captures are already SDR and bypass the query/conversion. `--tonemap-hdr` is retired. Capture v1 lacks source color metadata: unknown descriptions remain unchanged, and other compositors returning SDR from HDR outputs require a documented exception. Packed 8-bit/10-bit HDR uses CPU-width SIMD plus per-code PQ/shoulder LUTs; frames at least 1920×1080 share one peak/LUT set across four existing Io workers. Other formats use the scalar reference. Differential checks cover packed formats, tails, strides, and alpha. `zig build -Doptimize=ReleaseFast bench-capture` compares scalar/SIMD CPU conversion costs on gray and colored input.
- **Recorder timing and HDR** (otter-rec): Submit each captured frame once with elapsed-time PTS; never fill missed intervals with duplicate encode calls. Retain the last frame to mark stop time, use atomic signal flags, and keep software x264 on `veryfast`/`zerolatency` so Stop does not flush a lookahead backlog. Native Wayland output/region frames use active color descriptions and shared HDR conversion before encoding. KMS protocol v2 carries active PQ metadata; NVIDIA performs region-peak reduction, BT.2390 and BT.2020-to-sRGB conversion on GL textures without CPU readback. Map GL/CUDA resources only around each copy. Files declare sRGB transfer, BT.709 primaries/matrix. Raw capture APIs remain raw; never infer HDR from bit depth. `tests/recording_stop.py` runs in a VM; `tests/gpu.sh` tests synthetic 4K60 GL/CUDA/NVENC frames without capturing the desktop.
- **Screenshot annotations and OCR**: `otter-render/src/annotation.zig` owns the bounded vector document, undo/redo, hit testing, and CPU rasterizer shared by `otter-screenshot --annotate` and the `otter-shot` GUI. `selection_overlay.EditorCallbacks` continue on the same layer surfaces after region selection: editor buffers are transparent outside the frozen selection, keep its image at the captured coordinates, and provide tool-specific cursors. Both editors use the semantic Tabler annotation icon set with hover tooltips. The dedicated `otter-tools-core` `otter_ocr` module runs the system `tesseract` CLI and copies recognized text to the clipboard; missing Tesseract disables OCR only.
- **Shared model packages**: production model lookup is rooted at `/usr/share/otter-shell/models/{assist,transcribe,vox}`. `otter-zenith` packages those weights independently as architecture-independent `otter-assist-model`, `otter-transcribe-model`, and `otter-vox-model`; app-local paths remain source assets for packaging, not runtime fallbacks. Explicit development model flags still override the shared paths.
- **Transcribe phrases**: `otter-transcribe` uses native Parakeet TDT 110M FP16 (`tdt_ctc-110m-f16.gguf`) with WebRTC VAD and adaptive acoustic gaps in `src/phrase.zig`. Capture is 16 kHz on a PipeWire thread loop; bounded preallocated buffers swap under that loop lock and wake the main loop through eventfd, so inference/typing cannot starve capture. Stop joins the producer before draining PCM; overflow stops capture explicitly. Keep 20 ms frames independent of PipeWire callback boundaries. Short energy gaps need VAD agreement; sustained gaps can overcome VAD hangover. Track recent speech energy and a two-second noise floor, extending waits in noise. Preserve speech PCM, retain a 320 ms lead-in while idle, require two seconds of context for short acoustic gaps, let sustained VAD pauses with low energy flush shorter endings, flush on Stop, and retain the 12-second safety cap. `pause_ms` defaults to 400; `src/parakeet.zig` retains recognition context across phrase boundaries, adds 320 ms of decode-only silence, and re-decodes the current context; commit at the first boundary after 60 seconds (72 seconds maximum input including the next phrase, plus padding). New hypotheses replace provisional text, including words and punctuation. Focused output diffs against actually delivered text, sends 24-byte/key batches without per-key sleeps, never retries ambiguous edits, and suspends on reported window-focus changes or non-ASCII suffix deletion; caret changes inside a window remain unobservable. Clipboard and stdout emit complete snapshots; `stream=false` emits only the final snapshot. Benchmark the production segmenter and decoder through `benchmarks/build.sh`, including pace changes, background noise, completion delay and forced-cut counts. App and model packages must be released together for the initial model switch.
- **CommandList + Quad Renderer** (otter-render): All apps buffer draw commands via `DefaultCommandList` (solidRect, blendRect, roundedSolidRect, roundedBlendRect, roundedRectOutline, text, image, sprite, scissorPush/Pop, etc.), then `quad_renderer.rasterize()` plays them back with scissor clipping and damage culling. Text measurement: `font.measureTextAtScale(text, size, cmds.scale)`.
- **Terminal Rendering Boundary** (otter-vte): Terminal views use `DynamicCommandList`, `PowerlineOps`, `BlockOps`, `cell_glyphs`, and `CellRenderer(...)` from `otter-vte`. Apps provide terminal/session state and comptime hooks, while terminal cell rendering stays in the shared package so other apps can embed terminal output without copying `otter-term` internals.
- **Terminal Scrollback Compression** (otter-term): `app/compression.zig` caches each libghostty-vt activity token, waits 250 ms after terminal activity, then schedules one incremental compression step per event-loop pass until the API reports complete or unsupported. Scheduler state follows each tab/split; logical scrollback content and limits remain unchanged.
- **Terminal libghostty boundary** (otter-term): libghostty-vt owns paste sanitizing, word/line selection semantics and tracked active selections, OSC 7/9/1337 PWD parsing, OSC 8 hyperlinks, Unicode grapheme widths, cursor visuals, palette generation, and terminal protocol reports/callbacks (focus, resize, color scheme, device attributes, XTVERSION, clipboard writes). Otter supplies Wayland policy/UI and sources terminal colors from `otter-term.conf`; UI chrome uses `otter-theme` tokens.
- **Text System Boundary** (otter-render): `src/text.zig` owns the backend boundary for HarfBuzz shaping, itijah bidi checks/layout, and Fontconfig translate-C. `TextSystem.measure` preserves the current FreeType fast path for ASCII/simple LTR and uses HarfBuzz advances plus itijah layout for complex text. `TextSystem.draw` renders shaped glyph IDs through cached FreeType glyph-index rasterization and routes `.notdef` clusters back through the existing fallback chain. `itijah` is vendored at latest main commit `a8a70fc73ea7bcfcffd260e390521c521c1e8490` with a Zig 0.16 build wrapper.
- **Border Radius** (otter-render/otter-theme): SDF-based rounded rect rendering via `sdf.zig`. `Theme.Layout` supplies `control_radius`, `panel_radius`, and `joined_radius`; pill radius is derived. CommandList: `roundedSolidRect`, `roundedBlendRect`, `roundedRectOutline` with `corners: u4` bitmask (bit0=TL, bit1=TR, bit2=BL, bit3=BR). Zero-radius fast-paths to existing sharp rect logic. Compositor border radius sent via `set_borders` protocol request with `radius` argument.
- **Damage Tracking** (otter-wayland): `DamageTracker` accumulates dirty rects with double-buffer support. Falls back to full redraw on overflow.
- **UI command storage** (otter-ui): `Capacities.command_storage = false` is only for input/layout states whose application owns an external command list. Rendering entry points intentionally fail at compile time for those states. Rendering apps keep the default bounded command capacity unless measured frame maxima and overflow behavior prove a smaller capacity safe.
- **Monitor storage and aggregation** (otter-desktop/otter-monitor): Process, previous-process, desktop catalog, and visible/sort storage retain dynamic capacity proportional to observed counts. Application aggregation uses the sorted PID index and compact desktop catalog indices; do not restore fixed maximum-sized tables or per-process desktop strings.
- **Search index lifecycle** (otter-tools-core/otter-search): File-index arrays grow geometrically within the configured memory budget; paths use one owned allocation per entry with relative/name aliases. Content trigram signatures are learned lazily from real queries, so startup does not read every indexed file. Content workers read the live index only while mutations are excluded; cancel and join them before watcher updates or index replacement. Inotify updates are incremental, with full rebuild reserved for queue overflow or watch invalidation.
- **Animation** (otter-render): Integer-only ease-out quadratic. `anim.tick(expanding)` advances, `anim.lerp(from, to)` interpolates. Handles mid-animation reversal.
- **Pub/Sub** (otter-wayland): `SubscriberList` for workspace, toplevel, and SysInfo state changes.
- **Keyboard/IME** (otter-wayland): `Keyboard` wraps xkbcommon with callbacks + timerfd repeat. `TextInput` wraps zwp_text_input_v3 for CJK/compose — check `isComposing()` to suppress direct key handling.
- **Drawing Primitives** (otter-ui): `drawing.zig` is a re-export barrel over `otter-ui/src/drawing/` (`core`, `text`, `frame`, `input`, `controls`, `select`, `dropdown`, `color_picker`). Roughly 60 stateless helpers with no coupling to app config structs: border, inputBox, wrappingInputBox, toggle, checkbox, colorSwatch, dropdown, dropdownOverlay, tabBar, scrollbar, formRow, sectionHeader, button, numberInput, progressBar, iconButton, textTruncated, wrappedText, colorPickerPopup, passwordInputBox, authStatusLine, maskUtf8, etc.
- **Drag selection** (otter-ui/otter-files): `otter_ui.DragSelection` owns viewport-clipped rubber-band geometry and visible-item selection baselines. Apps supply hit rectangles and apply `contains` results. Otter Files starts on blank pane space, supports additive Ctrl/Shift dragging, and leaves entry drags to file DnD. Pressing a selected entry preserves the full drag selection; an unmodified completed click collapses it. Stop on release, leave, navigation, keyboard actions, or scrolling; edge auto-scroll is not implemented.
- **ScrollState** (otter-ui): Vertical scroll tracking with `scroll(delta)`, `needsScrollbar()`, `thumbRect()`, `maxOffset()`.
- **Theme Layers** (otter-theme): `Theme` has exactly `colors`, `layout`, `spacing`, and `globals`. Colours expose exactly 12 roles: background, surface, surface_alt, foreground, muted, accent, on_accent, selected, border, success, warning, danger. Built-in palettes in `presets.zig` and `colors/*.conf` contain only those roles. Current/Bank are layout files; compact/standard/spacious are spacing files.
- **Universal Theming**: Widget configs use `?Color = null` for theme-mapped fields, resolved via `config.field orelse theme.colors.<role>` in root_container. Widget overrides win; otherwise every visual value comes from the resolved four-layer theme or its derived helpers.
- **Config Normalization**: On startup, apps parse and re-save configs (strips unknown fields, adds missing defaults). Bar menu, power, settings, and clipboard buttons are static presets; custom buttons use `otter-conf.Dynamic` indexed fields (`button_N_name`, `button_N_enabled`, `button_N_font_icon`, `button_N_command`, etc.) and appear in layouts as `button_<name>`. Legacy `button_<name>_*` fields are migrated to the indexed form. Optional fields (`?Color`, `?u16`) are NOT emitted. Only writes to `~/.config/otter-shell/`, never system configs.
- **Dock and Taskbar layer geometry**: `otter-dock` keeps compact bounds at rest, expands layer bounds for the magnification animation, waits for the matching configure before drawing, and detaches blur/buffers during signal-aware shutdown. `otter-taskbar` uses a bottom-anchored surface with a visible exclusive bar zone plus reserved overlay space; opt-in auto-hide releases that zone only when hidden and retains a two-pixel reveal target. Start, calendar, previews, and tray menus share the reserved Surface Description surface, with previews anchored to their app button and tray coordinates translated from the output origin.
- **Clipboard / DnD** (otter-wayland): `Clipboard` struct wraps `wl_data_device` for paste and drag-and-drop support. `getText()` creates a pipe, calls `offer.receive("text/plain;charset=utf-8", fd)`, polls with timeout, reads result. DnD accepts `text/uri-list` and text MIME offers, converts file URIs to shell-escaped paths, and invokes the registered drop callback. Used by otter-settings for Ctrl+V and otter-term for drop-to-paste.
- **Clipboard manager ownership** (otter-clip): The daemon caches every advertised MIME representation byte-for-byte in source order, including GNOME/Nemo copied-file and KDE cut/URI metadata. Takeover after dispatch is allowed only for a complete supported selection; rejected formats (including portal handles), failed/truncated reads, and format/byte limits cancel capture and leave the original owner in place. Replay eligibility is separate from text/image history previews. Reordering formats changes toolkit negotiation; never prioritize binary or text formats. A newer selection in that dispatch cancels the pending takeover. Ext data-control is preferred with wlr data-control fallback. The built-in `button_clip` bar button opens the launcher-backed history popup.
- **ConfigDoc** (otter-settings): Preserves comments, field order, and custom fields through edits. `serialize()` writes directly to disk without round-tripping through typed parser. `removeFieldsWithPrefix()` for bulk field deletion, `removeFromLayouts()` for layout cleanup (trims spaced names so widgets such as `dnd` return to the General layout + picker). `tabs.zig` registers one sidebar tab per app config file (including `otter-dock.conf` and `otter-taskbar.conf`). Bar layout chips list builtins from `editor_widgets.available_widgets` (`dnd`, `nightlight` included). Wallpaper path rows use the XDG portal directory chooser for global and per-display folders. Editable form values register exact text hit regions; active single-line editors keep fixed control bounds and horizontal-only padding so selection does not move or clip text.
- **Theme Loading** (otter-theme): `theme.conf` parses only `Theme.Globals`, including `colors_path`, `layout_path`, `spacing_path`, `icon_theme`, `icon_coloring`, `bar_islands`, `opacity`, and `blur`; the loader composes the three layer files into one `Theme`. First load migrates a legacy import graph to `theme.conf.legacy` plus three custom layers, writing the new root last. Four-layer themes with `bar_islands` in the selected layout remain compatible until the setting is saved at the root. Normal reloads are read-only. `ThemeWatcher` watches root and all three selected layers, including files created after startup; invalid reloads retain the active theme.
- **Sized Image Decode** (zigimg/otter-render): `Image.loadFromFileSampled` uses bounded JPEG/PNG statistical sampling for theme extraction. Render-facing `loadFromFileAtSize` / `loadFromMemoryAtSize` preserve aspect ratio and use alpha-aware box filtering for every registered format, decoding the source once without the former second full-size RGBA staging copy. NanoSVG resolves `currentColor` while parsing instead of copying and rewriting SVG text.
- **Hot-Reload**: `otter-conf.Watcher.watchConfigPath` watches the parent directory (atomic rename from otter-settings does not kill the watch). Event loops call `drainChanged()` then reload **once**. `IN_IGNORED` is not a change, so watch refresh cannot loop. Theme uses `ThemeWatcher` with the same drain. Bar, notifications, wallpaper, OSD, and idle poll watcher FDs for app config and theme.
- **Wallpaper State File**: `otter-wallpaper` writes `$XDG_RUNTIME_DIR/otter-shell/wallpaper-state` (legacy `/tmp/{uid}/otter-wallpaper-state` still read when present) with `output_name=wallpaper_path` lines on every wallpaper change and removes it on normal exit or catchable shutdown signals. Path construction lives in `otter-utils/src/runtime_state.zig`. Used by lockscreen/greeter/shot/theme-gen to display or consume matching wallpapers while wallpaper is running. `same_on_all_displays` defaults to true so all non-override outputs show the same image.
- **Fingerprint authentication**: Lock activates fprintd on demand, subscribes once to the service's exact device, and stops/releases before terminal callbacks or password PAM. Greeter's system `enable_fingerprint` setting exposes a separate PAM login action (`otter-greeter-fingerprint`); PAM status IPC is distinct from password prompts. Never authorize greeter login from a UI-provided fingerprint result. Lock damage geometry comes from the shared auth layout even when clock/avatar are hidden.
- **File defaults and density**: Open With's Always Open action runs `xdg-mime default` on its existing worker before launch; Open remains one-shot. File list rows derive height from font size, subtitle size, and theme Small spacing; rendering, materialization, and scrolling share that height.
- **Greeter compositor session**: `otter-greeter` launches its compositor through a dedicated root supervisor that owns the `greeter` PAM/logind session, then forks the unprivileged compositor inside that session with `LIBSEAT_BACKEND=logind`. The daemon watches both the greeter IPC socket and supervisor PID so compositor failures before UI connection are reaped and retried.
- **Theme Gen Output Policy**: `primary_output` selects which output wallpaper drives the single global generated colour layer. Empty/missing selections fall back to the lexicographically first output name, independent of compositor enumeration order. Per-output wallpaper rendering stays in `otter-wallpaper`; one global theme cannot carry simultaneous per-output palettes. Wallpaper-derived and manually selected palettes both map to the same 12 roles and drive every enabled external-app template.
- **Wallpaper SHM and catalog lifetime**: Each wallpaper surface keeps one single-buffer SHM pool in steady state. Never force-release or rewrite a compositor-owned buffer: allocate a replacement, retire the old pool until `wl_buffer.release`, then reclaim it after dispatch. Folder image lists store compact path references into one byte blob rather than fixed 4 KiB path slots.
- **Text file application matching** (otter-desktop): Explicit XDG Added Associations authorize types absent from the desktop file; Removed Associations are excluded from chooser results. Native XDG application enumeration and explicit launch share MIME matching. `text/plain` editors accept `text/*` source files, including Lua and C; binary types remain excluded.
- **D-Bus** (otter-desktop): UPower, PowerProfiles, MPRIS, SystemTray, NetworkManager, SCX Loader, Screensaver, ScreenSaverService, Logind, Notifications, Polkit Agent, Fprintd, switcheroo-control. All use sd-bus (vendored basu). **Important**: `sd_bus_process()` handles one message per call — must loop to drain.
- **Portal account, secret, and lockdown**: Account disclosure uses the shared native consent process and retains the displayed reply until approval. Secret derives per-app 32-byte values from a private atomically published master key under the XDG data directory; invalid storage never triggers key replacement. Lockdown combines user configuration with administrator constraints and emits property changes after edits; user values cannot clear administrator restrictions.
- **XDG Desktop Portal** (`xdg-desktop-portal-otter`): Otter-only backend for `xdg-desktop-portal`. It advertises all 21 impl interfaces in `otter.portal` so no foreign backend can claim them, validates every call against its contract, and answers only what Otter owns: native Settings reads and watches the shared `otter-theme` graph; native Wallpaper calls `otter-wallpaper --set`, so the daemon's watched config remains the only wallpaper state writer and lockscreen-only requests return failure; representable FileChooser `OpenFile`/`SaveFile`/`SaveFiles` requests use the `otter-files` OTFP v1 socket bridge with one bounded connect, one coalesced spawn, and one retry; Notification maps to `org.freedesktop.Notifications` directly; Screenshot delegates capture to `otter-screenshot` and PickColor to `otter-pick`; idle Inhibit maps to `org.freedesktop.ScreenSaver`; basic Access grant/deny prompts use the native portal dialog; ScreenCast CreateSession/SelectSources/Start selects monitors or windows through thumbnail cards and exports real frames through PipeWire after consent (synthetic frames exist only in the integration build); RemoteDesktop CreateSession/SelectDevices/Start/ConnectToEIS uses system libeis with virtual-pointer/keyboard inject and Notify* until EIS connects. Additional native handlers cover Access, Account, AppChooser, Background, Clipboard, DynamicLauncher, Email, GlobalShortcuts, InputCapture, Lockdown, Print, Secret, and Usb. FileChooser supports bulk-save names and choices; notifications forward actions/icons; Inhibit supports sleep and session monitoring; Screenshot supports regions and PickColor; Wallpaper provides preview; combined RemoteDesktop/ScreenCast sessions share stream mapping and teardown. Unsupported platform capabilities and unrepresentable requests fail closed with `org.freedesktop.portal.Error.Failed`; nothing forwards to GTK, GNOME, KDE, Hyprland, or keyring portals. Request and Session handles are caller-scoped and cancelled on `Close`, caller disconnect, or frontend disconnect.
- **Portal window capture**: Detect EXT toplevel capture, Hyprland toplevel export with mapped WLR handles, or the Mutter-compatible ScreenCast D-Bus service (also provided by Niri). Never match windows by title or crop monitors to imitate window capture. Preserve stable identities/provider ownership across consent, renegotiate window sizes, and close sessions when their source disappears. Native thumbnails load on a worker; temporary preview streams stop after capture. Combined remote-desktop sessions remain monitor-only. CUPS is optional at runtime and `Suggests` in Zenith; missing print tools must not stop the portal or client-rendered print-to-file.
- **Portal compositor boundary**: Detect Wayland protocol capabilities; never select a compositor by name, call compositor CLI IPC, or edit its bindings/configuration. The native Mutter-compatible ScreenCast service is a capture provider, not another portal backend. Optional vendor protocols must not prevent other portal interfaces from running. GlobalShortcuts registers actions and saves preferred triggers only; actual key assignment remains desktop-owned. InputCapture advertises zero capabilities when its protocol or output geometry is absent. RemoteDesktop Start requires native consent and enforces the approved device mask.
- **Portal installation and activation**: `xdg-desktop-portal-otter` generates D-Bus/systemd executable paths from `--prefix` without `DESTDIR` and keeps build-cache library paths out of the installed executable. Zenith packages the backend, activation files, and Otter selection with frontend/helper dependencies. Static user services activate through D-Bus; non-Otter sessions need an explicit desktop-specific `~/.config/xdg-desktop-portal/*-portals.conf` preference and the compositor must import its Wayland environment. `sh tests/run-install-check.sh` verifies `/usr` and `/usr/local` staging. The package includes `otter-portal-dialog`; `tests/test_screencast_live.py` verifies real frames through the public portal FD. Theme layer loads opt into `otter-conf` strict custom-value parsing to retain active colours on invalid reloads. RemoteDesktop remains incomplete (consent, keymap, geometry, and combined capture); CreateSession or an EIS FD is not proof of working input. See the portal audit for incomplete native methods and remaining stubs.
- **Pika tiling desktop providers**: Hyprland, Niri, and Mango select Otter apps and portal through desktop-specific defaults. Never use package-wide conflicts to remove other desktop environments or their apps during upgrades. `pika-shell-profile-common >= 0.1.4` permits coexistence and avoids global XDG defaults. Legacy-app cleanup is confined to fresh Full ISO construction. Native onboarding helpers use private paths so GTK counterparts can remain installed.
- **Plugin desktop services**: `otter-bar` and `otter-launcher` dynamically link `libotter_desktop.so.0`; plugins call its stable C service ABI instead of linking systemd or embedding BASU.
- **XDG semantic icons**: `otter-ui/src/icons.zig` maps every bundled semantic icon to an XDG icon name. Selected themes use `-symbolic` variants with theme colouring or regular variants without it; app/content surfaces request regular variants first, with tinted symbolic fallback. Missing theme icons fall back to bundled SVGs. `sd_bar_item` resolves arbitrary names through the same selected XDG theme. Icon-only buttons omit text gap so 20 px plugin slots remain centered and visible.
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
| Hyprland handle → address map | `otter-wayland/src/toplevel_map.zig` |
| Compositor blur regions | `otter-wayland/src/background_effect.zig` |
| Keyboard handler | `otter-wayland/src/keyboard.zig` |
| Clipboard | `otter-wayland/src/clipboard.zig` |
| switcheroo-control GPU list | `otter-desktop/src/switcheroo.zig` |
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
| Dock hover thumbnails (spec) | `otter-dock/src/thumbnail.zig` + `ext_image_copy_capture` / `ext_foreign_toplevel_list` (see `docs/superpowers/specs/2026-03-30-otter-dock-design.md`) |
| Dock theme roles | `otter-theme/src/theme.zig` (`Theme.colors`, `Theme.layout`, `Theme.spacing`, and derived `dockBackground`/`dockBorder`) |
| Taskbar entry point / layer surfaces / rendering | `otter-taskbar/src/main.zig`, `otter-taskbar/src/shell.zig`, `otter-taskbar/src/draw.zig` |
| Taskbar state and layout | `otter-taskbar/src/state.zig`, `otter-taskbar/src/layout.zig` |
| Taskbar Start panel | `otter-taskbar/src/start_menu.zig` |
| Taskbar hover previews | `otter-taskbar/src/preview.zig` + `ext_image_copy_capture` / `ext_foreign_toplevel_list` |
| Taskbar config | `otter-config-types/src/taskbar.zig` |
| Taskbar settings | `otter-settings/src/tabs.zig`, `otter-settings/src/editor.zig` |
| Terminal app | `otter-term/build.zig` (Zig 0.16 app linking installed `libghostty-vt`; Otter owns Wayland/PTY/render frontend) |
| Terminal scrollback compression | `otter-term/src/app/compression.zig`, `otter-term/src/terminal/core.zig` |
| File manager app / UI | `otter-files/src/main.zig`, `otter-files/src/shell.zig`, `otter-files/src/model.zig` |
| XDG desktop portal backend | `xdg-desktop-portal-otter/src/main.zig`, `xdg-desktop-portal-otter/src/broker.zig`, `xdg-desktop-portal-otter/src/native.zig`, `xdg-desktop-portal-otter/src/native_settings.zig`, `xdg-desktop-portal-otter/src/native_wallpaper.zig`, `xdg-desktop-portal-otter/src/native_notification.zig`, `xdg-desktop-portal-otter/src/native_screenshot.zig`, `xdg-desktop-portal-otter/src/native_inhibit.zig`, `xdg-desktop-portal-otter/src/native_screencast.zig`, `xdg-desktop-portal-otter/src/screencast_feed.zig`, `xdg-desktop-portal-otter/src/native_remotedesktop.zig`, `xdg-desktop-portal-otter/src/eis_server.zig`, `xdg-desktop-portal-otter/src/picker.zig` |
| Portal contracts, ownership, and routes | `xdg-desktop-portal-otter/src/contracts.zig`, `xdg-desktop-portal-otter/src/ownership.zig`, `xdg-desktop-portal-otter/src/routes.zig` |
| Portal integration tests and packaging | `xdg-desktop-portal-otter/tests/`, `xdg-desktop-portal-otter/data/` |
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
| Assistant app entry | `otter-assistant/src/main.zig` |
| Assistant daemon | `otter-assist/src/main.zig` |
| Search daemon | `otter-search/src/main.zig` |
| Screenshot tool | `otter-screenshot/src/main.zig` |
| Screenshot annotation overlay | `otter-screenshot/src/annotator.zig`, `otter-render/src/annotation.zig`, `otter-tools-core/src/ocr.zig` |
| System monitor | `otter-monitor/src/main.zig` |
| Package manager app / helper | `otter-pkg/src/main.zig`, `otter-pkg/src/app.zig`, `otter-pkg/src/helper.zig` |
| Package manager model / UI | `otter-pkg/src/backend.zig`, `otter-pkg/src/state.zig`, `otter-pkg/src/draw.zig` |
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
| Small tools shared core | `otter-tools-core/src/root.zig`, `otter-tools-core/src/clip_history.zig`, `otter-tools-core/src/record.zig`, `otter-tools-core/src/color.zig`, `otter-tools-core/src/splathash.zig`, `otter-tools-core/src/theme_palette.zig`, `otter-tools-core/src/calendar.zig`, `otter-tools-core/src/emoji.zig`, `otter-tools-core/src/duration.zig`, `otter-tools-core/src/weather.zig`, `otter-tools-core/src/calc.zig`, `otter-tools-core/src/assist_client.zig`, `otter-tools-core/src/knowledge.zig`, `otter-tools-core/src/web_search.zig` |
| Clipboard manager | `otter-clip/src/main.zig`, `otter-clip/src/copy.zig`, `otter-clip/src/paste.zig` |
| Screen recorder | `otter-rec/src/main.zig`, `otter-rec/src/portal_recorder.zig` (portal PipeWire stream capture) |
| Color picker | `otter-pick/src/main.zig` |
| Calendar popover | `otter-cal/src/main.zig` |
| Emoji picker | `otter-emoji/src/main.zig` |
| Timer | `otter-timer/src/main.zig` |
| Sticky notes | `otter-note/src/main.zig` |
| Weather helper | `otter-weather/src/main.zig` |
| Weather bar widget | `otter-ui/src/widgets/weather.zig` |
| DND bar widget | `otter-ui/src/widgets/dnd.zig`, `otter-ui/src/widgets/specs/dnd.zig` |
| Calculator | `otter-calc/src/main.zig` |
| Voice TTS CLI | `otter-vox/src/main.zig`, `otter-vox/src/runtime.zig`, `otter-vox/src/tokenizer.zig`, `otter-vox/src/audio8_bridge.cpp` (Audio8 Q5_0/FP16 GGUF, shipped pre-cloned voice codes, selectable Vulkan GPU with CPU fallback, chunked PipeWire playback) |
| Auto clicker | `otter-clicker/src/main.zig`, `otter-clicker/src/virtual_pointer.zig`, `otter-clicker/src/uinput.zig` (shared point overlay + Wayland virtual-pointer injection with uinput fallback) |
| PipeWire one-shot/streaming playback | `otter-desktop/src/pipewire_playback.zig` |
| Interaction cues | `otter-cue/src/root.zig`, `otter-cue/src/recipe.zig`, `otter-cue/src/engine.zig`, `otter-cue/src/bind.zig`, `otter-cue/src/playback.zig` |
| Config type definitions | `otter-config-types/src/root.zig` |
| Polkit agent entry | `otter-polkit/src/main.zig` |
| Overview / switcher overlay | `otter-overview/src/main.zig`, `otter-overview/src/layout.zig`, `otter-overview/src/hypr.zig`, `otter-overview/src/sway.zig`, `otter-wayland/src/protocols/niri.zig` (`otter-switcher` is the second installed executable and limits Alt-Tab to the active workspace; mouse hover selects, click activates, and wheel cycles. Sway uses native `swaymsg` tree/focus IPC. Hypr 0.56 export skips windows that miss the monitor; overflow columns use a temporary scrolling-tape nudge, not a window swap; bottom strip click-scrolls the matching workspace card and paints mini window tiles, centered on the card strip; Ctrl+1..9 / Ctrl+0 jump the same indices without feeding digits into search). Mapped overlay 1:1 3-finger swipe via `zwp_pointer_gestures_v1`; touchpad workspace scroll snaps on axis stop. Optional Hyprland 0.55+ lua `otter_hypr_layout.overview_gesture.install()` is compositor bind for *opening* from the desktop and accepts `open_direction` / `close_direction` options |
| Keybind help overlay | `otter-keybindhelp/src/main.zig`, `otter-keybindhelp/src/parser.zig`, `otter-keybindhelp/src/normalize.zig`, `otter-keybindhelp/src/draw.zig`, `otter-keybindhelp/src/shell.zig` |
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
| Shot annotation GUI | `otter-shot/src/annotation_editor.zig`, `otter-shot/src/ui/annotation_toolbar.zig` |
| Logind D-Bus client | `otter-desktop/src/logind.zig` |
| ScreenSaver service | `otter-desktop/src/screensaver_service.zig` |
| Polkit D-Bus agent | `otter-desktop/src/polkit_agent.zig` |
| PAM authentication | `otter-desktop/src/pam.zig` |
| Fprintd D-Bus client | `otter-desktop/src/fprintd.zig` |

Each app follows the pattern: `<app>/src/main.zig` (entry), `config.zig` (schema), `draw.zig` (renderer).

## Vendored Dependencies

- **basu** (`otter-desktop/vendor/basu/`): Standalone sd-bus from systemd. No runtime libsystemd dependency.
- **PipeWire** (`otter-desktop/vendor/pipewire/`, from `allyourcodebase/pipewire`): Zig bindings with dlopen shims. Statically linked.
- **itijah** (`otter-render/vendor/itijah/`): Zig-native Unicode Bidirectional Algorithm, vendored from latest main with a local Zig 0.16 build wrapper.
- **ggml** (`otter-vox/third_party/ggml/`): MIT C/C++ runtime boundary for Audio8 inference; Vulkan is preferred with native CPU fallback.

## Configuration Format (otter-conf)

Flat key-value format with `#` comments. Nested struct flattening: `clock_text_color` maps to `config.clock.text_color`. All config struct fields must have defaults. Supported types: booleans, integers, floats, strings, enums, arrays, slices, optionals, custom parse/toStr types, nested structs. Unknown fields silently skipped. `Dynamic(T, prefix)` indexed entries are capped at indices `0..4095` (`parser_support.max_dynamic_entries`); import nesting is capped at depth 128 (`import.max_import_depth`) and total merged output is capped by `LoadOptions.max_file_size`.

Widget configs use `?Color = null` for theme-mapped fields. Resolved at widget init: `config.field orelse theme.token`. Serializer omits null fields, keeping configs minimal.

### Theme Configuration

Config: `~/.config/otter-shell/theme.conf` (fallback: `/etc/otter-shell/`, then compiled-in defaults). Root contains only `colors_path`, `layout_path`, `spacing_path`, `font_family`, `font_size`, `icon_theme`, `opacity`, and `blur`. Selected files use flat keys matching `Theme.Colors`, `Theme.Layout`, or `Theme.Spacing`; no prefixed duplicate roles exist.

### Visual profiles and verification

Theme resolution composes one selected Colours file, one Layout file, one Spacing file, and root Globals. Apps consume semantic roles and derived helpers; they do not branch on file names. Settings writes custom layers independently and exposes four matching editor tabs. Theme Gen writes only `generated-colors.conf`. Colour files cannot change structure, spacing, typography, icons, opacity, or blur.

Current is a dark continuous-plane system with one 4 px radius on standalone app controls, rows, panels, popups, decorations, and dock slots; only true joined edges are square. Its compact Bar has a feature/anatomy compatibility contract, not a pixel freeze: visual tokens may change its palette/radii, but preserve the rounded active workspace chip, real SVG/font icons, live widget content, dense packing, centered title, and lack of invented workspace/title indicators. Global `bar_islands` makes the Bar rail transparent and gives each left/center/right section its own surface; when global blur is enabled, the blur region must be clipped to those section surfaces so gaps remain clear. Current's 2 px line is reserved for focus, status, and progress surfaces. Bank is warm mineral and all-dark: opaque dark planes, with square markers and short baselines reserved for status, workspace, and progress; it must not introduce light panels, split light/dark surfaces, or required blur. Generic navigation/list selection uses tonal fill only in both profiles. Both profiles use CPU-renderable fills, lines, and rounded rectangles. A selected or focused control uses one thin outline/focus ring or one line/marker, never both.

Long-running apps use `ThemeWatcher`, watching `theme.conf` and all three selected paths, including a missing selected file created after startup. A layer parse/read failure retains the previous valid theme and logs the error; it must not publish partial/default state or rewrite files. Only one-shot legacy migration and explicit Settings/Theme Gen actions write theme files.

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

`BackgroundEffect` owns compositor blur regions for translucent surfaces. `XdgToplevel` wrapper provides reusable toplevel window lifecycle with configure handling and HiDPI scale tracking.

## C Dependencies

**Dynamic**: Fontconfig, wayland-client, xkbcommon, PAM (optional), Vulkan loader (`otter-vox`). **Zig-packaged/static**: FreeType (`allyourcodebase/freetype`), HarfBuzz (`allyourcodebase/harfbuzz`). **Vendored**: basu (sd-bus), PipeWire, itijah, ggml. **Pure Zig**: zigimg (raster image formats), zeit (timezone/date).

## Widgets (otter-ui/src/widgets/)

All bar widgets embed a `Widget` shell for geometry/motion state and implement struct methods for draw/input. Key widgets:
- **clock** - Time display via zeit, left-click calendar popover (stays until click-off), global minute tracking
- **workspaces** - Workspace indicator/switcher via ext-workspace protocol
- **battery** - UPower D-Bus; click menu lists batteries plus power profiles; auto-hides when no battery
- **brightness** - Sysfs panel + keyboard LED + optional ddcutil DDC; click menu, scroll primary
- **cpu_load/cpu_temp/memory** - System metrics via SysInfo with threshold colors; cpu_temp click lists CPU/GPU hwmon sensors
- **active_window** - Focused window title via foreign_toplevel
- **button** - Clickable icon button with command execution
- **power_profiles** - Power profile selector via D-Bus
- **network** - NetworkManager D-Bus with WiFi, OpenVPN/WireGuard VPN, and Wi-Fi password prompt
- **weather** - Cached Open-Meteo current temperature with 7-day popup, popup refresh action, and optional public-IP location detection in `otter-weather`
- **volume** - PipeWire audio control with per-device popup
- **falcond** - Daemon status via inotify
- **mpris** - Media player via MPRIS D-Bus
- **system_tray** - StatusNotifierItem icons with animated expand/collapse, DBusMenu context menus
- **dnd** - Shared runtime Do Not Disturb state toggle with bell/bell-off SVG status icons
- **nightlight** - Night Light toggle (left-click `otter-nightlight`; right-click temperature/schedule/suspend menu)

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

## Installer program packaging

`otter-installer`, `otter-first-setup`, and `otter-welcome` are packaged by `otter-zenith` from explicit source refs. Installer automatic partitioning must always receive an explicitly selected drive and reject mounted/read-only disks; never restore implicit first-disk selection. The installer uses native catalog selectors and always defers account creation to First Setup. Running progress cannot be dismissed or marked complete before the helper exits successfully. `images/pika-iso` builds Minimal and Full through a manual Gitea workflow using Cockatiel packages. Successful main builds call `release.sh` to publish each ISO with matching basename-relative `.md5` and `.sha256` files to `iso.pika-os.com`, then retain downloadable Gitea artifacts. CDN publishing failures must fail the build.

Minimal ISO media uses explicit runtime packages, `kernel-pika-runtime`, and `linux-firmware-installer`, with `nmtui` for optional online installation. Keep PC network/storage firmware, omit GPU/audio/ARM SoC and switch/SmartNIC bundles, and boot its text console through the EFI framebuffer (`nomodeset`). Do not pull kernel headers/toolchains, Plymouth, or `locales-all` onto text media; generate the chosen locale during installation. Full desktop dependencies replace the installer firmware subset with `linux-firmware`. `pikainstall` schema 1 defaults `modules_online` to false; Full reads a mounted local package repository and may satisfy dependencies from packages already installed in the live filesystem. Pool pruning must match installed status, package name, version, and architecture exactly, after live cleanup. Size gates and a local-only module resolver check run before publishing ISO artifacts.

Pika installer frontends share native installation stages, Zig catalogs, and disk validation/preparation in `pikainstall >= 3.5.0`; the backend holds `/run/pikainstall-install.lock` across preparation and apply. Minimal uses a Zig-driven newt wizard with system locale/XKB/timezone catalogs and hidden passwords. `--dry` must never prepare or apply. `pika-baseos-minimal` and `otter-greeter` require `login`; both ISO recipes verify the live user PAM stack, including greeter autologin on Full, before image creation.

Pika keyboard settings use one canonical `/etc/vconsole.conf` containing both `KEYMAP` and the XKB fields. `/usr/lib/tmpfiles.d/debian.conf` forcibly recreates `/etc/default/keyboard` as an alias to it at boot; never split the settings between separate files. Verify selected keyboard settings after an installed-system reboot.

Installer raw Linux syscalls use `std.os.linux.errno`, including nonblocking progress reads; `std.posix.errno` follows libc when linked and cannot decode raw negative syscall returns. Live image detection uses `/live/filesystem.squashfs`; pool discovery supports `/pool`, `/cdrom/pool`, and `/run/live/medium/pool`. Factory Otter theme roots select generated colours plus installed layout/spacing files, and Hyprland ships a seed `otter-theme.lua` so the generated file is watched from first login.

Installer automatic storage defaults to XFS; ext4/Btrfs, encrypted root/home, home subvolumes, swap sizing, and rEFInd options share guarded backend validation. Manual assignments never format and must validate root, boot, and EFI before mounting. Finalization regenerates the initramfs after persistent storage configuration. Both backend and TUI builds explicitly target x86-64-v3. Native selector rendering must supply the frame allocator for shared chevron icons and deinitialize UI state caches.

First Setup and Welcome import otter-pkg's onboarding module for native APT previews, helper transactions, and driver selection. Keep one libapt context per process; close caches and transfer context ownership between serialized workers. Root account/completion operations run off the Wayland thread. `pikainstall complete-task` persists independent flags, with identity completion preserved when optional tasks are saved. Checkboxes select available CFHDB package profiles; installed profiles are read-only, and package scripts never come from profile data.

- **Welcome shell content** (`otter-welcome`): Show shell docs, tips, and switching guidance only in Hyprland, Mango, or Niri sessions. Tips use a dismissible modal with keyboard navigation. Shell switching opens the guide; do not launch `pika-shell-apply` as a chooser because it only copies an already-installed profile.
  Packaging requires `pika-shell-profile-common` plus an alternative dependency on the mutually exclusive Otter/Noctalia/Dank profiles, defaulting to Otter.

Live ISO graphics selection belongs to `pika-iso` and `pika-live-booster-hooks`: the standard Full entry permits Nouveau; RTX mounts a complete NVIDIA driver layer before switching root and blocks competing modules. Build modules for the exact live kernel, verify GSP firmware and runtime libraries, and wait for the selected driver before starting the greeter. Cached debs are not proof of a usable live driver. Fallback keeps `nomodeset` and blocks both drivers.

Native Pika installation must not hand schema-based apply requests to the legacy Python/host/chroot installer. Clear old filesystem signatures on automatically erased partitions, refresh device metadata, and mount known formats explicitly. Manual assignments preserve existing home and unrelated EFI files. Keep live, deferred first-boot, OEM, and base-only autologin intact. Suppress console diagnostics for the entire TUI while retaining kernel logs; remove live-only services and installer autostart from installed systems. Full includes Blivet for partition editing and a launcher entry for Otter Logout. Both ISO recipes include the official Ventoy runtime helper and compatibility marker so selected renamed/nested images resolve without separate retry delays.
Minimal must support offline base installation and carry full `kernel-pika` with matching headers/toolchain and `systemd-cryptsetup`. Desktop or NVIDIA selections add full `linux-firmware`; manually retain these metapackages for upgrades. Configure headers/toolchains before NVIDIA and verify modules for every installed kernel. Default installed boot entries retain modesetting; only explicit safe graphics uses `nomodeset`. Remove live-only service masks from installed systems.
TUI-created desktop users use normal login and omit the First Setup package; purge inherited live-image copies of First Setup. Welcome remains installed in every desktop mode. Deferred first-boot and OEM desktop modes retain First Setup. Preserve autologin for deferred first-boot identity, OEM, and base-only installs. Retired live accounts must lose admin groups and interactive login. Deferred accounts receive missing desktop defaults from `/etc/skel`; installed DNS uses NetworkManager’s runtime resolver, never the build-container resolver. Niri relies on XDG onboarding autostarts; Hyprland retains a guarded explicit onboarding sequence that launches Welcome even when First Setup is absent. Neither auto-opens the package manager; First Setup holds one per-user runtime lock. Polkit prefers the logged-in user only among identities offered by policy, keeping the displayed and authenticated identity identical.

- **Launcher recents**: `recent_apps` defaults to false. When enabled, successful launcher requests persist up to 32 desktop IDs in the XDG cache and show them before alphabetical entries. Search ordering stays independent.

- **Settings theme edits**: Theme fields use the shared input buffer for selection and word deletion. String edits retain independent owned storage. Explicit layer paths survive Apply; selecting a preset or editing layer values replaces the corresponding path. Custom palette files serialize `Theme.Colors`, matching their loader. Theme layer paths support `~/` expansion.

- **Files mouse history**: Side/extra and dedicated Back/Forward mouse buttons use the existing model history on press; modal input remains handled first.

- **Notes startup**: Flush Wayland requests before the blocking poll, including the first buffer commit. `otter-note/tests/startup.py` checks mapping without input in a Hyprland VM.

- **Application shortcut search**: Shared application-name matching accepts case-insensitive ordered letter subsequences; desktop IDs and keywords retain substring matching.

Minimal TUI manual partitioning uses the shared safe drive catalog and GNU parted. Partition edits are immediate; selected filesystem formats occur only after final confirmation and validation. Omitted manual format fields preserve filesystems and legacy resume hashes. Keep existing EFI/home files by default. Both installer completion screens report elapsed time; TUI selects Reboot by default.

- **XDG application discovery** (otter-desktop): Empty XDG data/config variables use their standard defaults, including `/usr/local/share:/usr/share`. Non-empty `XDG_DATA_DIRS` remains authoritative. `PathList` owns appended path text but contains internal slices, so fill it in caller-owned storage rather than returning it by value.

Shared Pika desktop assets require `pika-wallpapers`, which supplies the wallpaper directory alias used by desktop defaults. Desktop settings postinst migrations must never leave background processes inside installer chroots; enable their existing boot service instead. Opening retained First Setup with no pending tasks shows a completed state, never another account-creation wizard.

- **File manager activation**: Desktop-specific MIME files contain only Default Applications. Zenith ships `otter-files-session`: when Otter is the selected directory handler, it installs a managed FileManager1 service in `$XDG_RUNTIME_DIR/dbus-1/services` and reloads D-Bus activation config. It preserves explicit user/runtime overrides and never rewrites user MIME preferences. XDG autostart and Otter compositor profile fragments invoke it at login.

- **Package review and updates** (otter-pkg): Cache architecture-aware hold confirmation counts per preview, never scan the catalog per draw. The Recommended tab compares real plans with recommends enabled/disabled; APT caches that policy, so config changes require reopening the cache with the caller's original lock mode. Rebuild stale package refs afterward. Held lists include upgradable packages absent from selective plans; kept-back/phased entries never require permission to change holds. Resolve dependency names before freeing their owning detail page; unavailable targets preserve that page and its navigation trail. Unmark all clears persisted marks from browse and review. Review navigation uses native tabs with overflow arrows. Check & apply updates refreshes first and only auto-applies when no saved selections, kept-back packages, removals, downgrades, or hold/essential confirmations require review. `otter-pkg-updates` owns one APT context on its polling worker, exports a single StatusNotifierItem, and reads metadata without elevation. The separately packaged `otter-pkg-refresh.timer` refreshes repository metadata every six hours and never installs packages. Use ReleaseFast `resolver-check`, `tray-check`, and actual-tree review fixtures for regression coverage.

- **Modal portal clients**: Shot and Settings use `portal_file_chooser.chooseFile` parent event callbacks, keeping Wayland dispatch live while modal and cancelling when the parent closes.
- **Portal initial-folder hints**: Treat an empty NUL-terminated `current_folder` as unset, including Steam's first Browse request. Preserve validation of non-empty paths and let `current_file` supply its parent when the folder hint is empty. Regression coverage must go through the public FileChooser frontend as well as the backend parser.
- **Print defaults**: Omit unset PreparePrint resolution strings; empty strings become zero DPI in GTK and can blank raster output. Select menu roots fill their full option bounds.
- **Microphone OSD**: `otter-osd microphone-mute-toggle` toggles the default PipeWire source. Track observed sink state separately so unrelated callbacks cannot overwrite the microphone display.

- **Browser appearance and memory**: Read the portal `color-scheme` and update WPE dark mode for live web content. Select the document-browser cache model before creating any WebContext (including the extension bridge), so unused page processes exit after tab closure while resource/back-forward caching remains. `otter-browser/scripts/tab-memory-test.sh` checks reclamation and surviving-page navigation in headless Sway.
