# Otter Shell UI

Language for describing Otter Shell's shared UI model and the surfaces that use it.

## Language

**Desktop Search**:
A shell-level way to find user-visible files and folders across configured personal locations. It is not code workspace search and should not assume a git repository, project root, or developer workflow.
_Avoid_: Workspace search, repo search, code search

**Search Root**:
A configured directory tree included in Desktop Search. Built-in Search Roots are XDG user directories, `$HOME/.config`, and direct children of `$HOME`; users may add explicit Search Roots through the settings UI.
_Avoid_: Project root, repo root, workspace root

**Search Exclusion**:
A directory or file pattern Desktop Search deliberately leaves out to avoid private, generated, cache, dependency, or high-churn content. Default Search Exclusions include hidden directories except `$HOME/.config`, VCS folders, caches, dependency/build outputs, `$HOME/.local`, and `$HOME/.cargo`.
_Avoid_: Ignore rule, gitignore rule

**Path Search**:
The primary Desktop Search mode for finding files and folders by name or path. It should stay useful even when content indexing is limited or disabled.
_Avoid_: FZF mode, filename-only search

**Content Search**:
The secondary Desktop Search mode for finding text inside indexed files. It is capped by file type and size so desktop-wide indexing does not turn every user file into resident search state.
_Avoid_: Ripgrep mode, full-text archive

**Desktop Search Tool**:
An Assistant Tool that queries Desktop Search through `otter-search` after explicit user approval in the Assistant App, unless the user has enabled app-wide always-allow.
_Avoid_: Private Knowledge Retrieval, hidden home scan, model file access

**Assistant Service**:
The shared local assistant capability used by Otter Shell consumers when they need model responses or explicit assistant tools. It is distinct from any one graphical assistant surface.
_Avoid_: Model runner, assistant UI backend

**Assistant Socket**:
The Unix socket protocol used by Otter consumers to talk to the Assistant Service directly.
_Avoid_: CLI subprocess bridge, shell command integration

**Assistant Client**:
The shared Otter library code that formats Assistant Socket requests, parses Event Stream Responses, and handles Approval Continuations for CLI and graphical consumers.
_Avoid_: App-local socket protocol, duplicated CLI parser

**Assistant App**:
The user-facing XDG toplevel for chatting with the Assistant Service and managing saved chat threads.
_Avoid_: otter-assist UI, monitor-style assistant backend

**Assistant Markdown**:
The rendered answer format in the Assistant App. It includes common Markdown text, links, tables, cached remote images, task lists, and fenced Code Blocks, but excludes raw HTML and math.
_Avoid_: HTML answer, plain transcript, browser document

**Code Block**:
A fenced code region inside Assistant Markdown. Code Blocks are highlighted with `zhl` when the language is known.
_Avoid_: Raw preformatted blob, HTML code widget

**Cached Remote Image**:
A remote image fetched for display through Otter's image cache, then decoded and bounded before rendering. Assistant Markdown may show Cached Remote Images without treating raw HTML as renderable content.
_Avoid_: Inline web view, uncached remote image, raw HTML image

**Chat Thread**:
A saved conversation owned by the Assistant App for one user. The Assistant Service receives thread messages in a request, but does not own or persist Chat Threads.
_Avoid_: Assist session, model context, shared assistant memory

**Encrypted Chat Thread**:
A Chat Thread whose stored contents are protected for the owning desktop user. It is not shared assistant memory and should not be readable as plain text from the thread store.
_Avoid_: Plain history, global assistant log

**Thread Event**:
One appendable record in a Chat Thread, such as a user message, assistant message, tool observation summary, title change, or deletion marker.
_Avoid_: Database row, model token, raw transcript blob

**Thread Title**:
The short label shown for a Chat Thread. It starts as clipped first user text and is replaced once by an Assistant Service title suggestion unless the user renames it.
_Avoid_: Model summary, filename, conversation ID

**Assistant Tool**:
A capability the Assistant Service may invoke only when granted by an assistant interaction, such as search, retrieval, time, date, or weather.
_Avoid_: App plugin, background crawler

**Tool Approval**:
The Assistant App interaction that lets a user allow or deny a gated Assistant Tool call before it runs. Tool Approval shows the tool, query or location, mode, and result cap.
_Avoid_: Hidden permission, thread trust, model consent

**Approval Continuation**:
A follow-up Assistant Service request that resumes a paused assistant interaction after Tool Approval.
_Avoid_: Reverse callback, UI-owned tool execution

**Assistant Stream Event**:
A structured streaming item from the Assistant Service, such as thinking, tool requested, approval required, tool running, tool result, message delta, or final stats.
_Avoid_: Fake assistant prose, raw socket chunk

**Event Stream Response**:
A newline-delimited JSON response made of Assistant Stream Events. It replaces the older single-object JSON stream for assistant interactions.
_Avoid_: Partial JSON object stream, escaped message wrapper

**Tool Stats**:
Structured metadata returned with an assistant response that describes which Assistant Tools ran, were denied, and enough timing/source counts to explain the response path.
_Avoid_: Chat message, visible assistant prose

**Generation Stats**:
Structured metadata returned with an assistant response that describes model performance, including tokens per second and time to first token.
_Avoid_: Benchmark result, assistant prose, debug log

**Tool Evidence**:
Untrusted content returned by Assistant Tools and presented to the model as cited evidence, never as instructions.
_Avoid_: System prompt content, trusted context, hidden instruction

**Bounded Tool Loop**:
The Assistant Service's constrained cycle for choosing Assistant Tools, observing results, and producing an answer. It supports multi-step tool use but has explicit limits, including two web searches at most in the initial design, so the model cannot keep searching or drifting indefinitely.
_Avoid_: Open-ended agent, single preflight pass

**Tool Control Turn**:
A constrained JSON-only Assistant Service model turn that either requests one Assistant Tool call or proceeds to the final answer.
_Avoid_: Prose tool request, XML tag protocol, hidden chain of thought

**Web Search Tool**:
An Assistant Tool that fetches live web result metadata from Pika Search's JSON API after user approval, unless the user has enabled app-wide always-allow.
_Avoid_: Local metasearch daemon, browser automation, HTML scrape

**Web Result**:
Search metadata returned by the Web Search Tool, including title, URL, snippet, source, warning, timing, and optional infobox data. It is not a fetched copy of the target page.
_Avoid_: Crawled page, scraped article, cached webpage

**Weather Tool**:
An Assistant Tool that answers weather requests using an explicitly requested place when present, otherwise the user's configured Otter weather location.
_Avoid_: IP geolocation, implicit current location

**Knowledge Retrieval**:
An Assistant Tool that brings indexed documentation into an answer. It is preferred for Linux, Pika, and Otter support questions because the local model's built-in knowledge is small and may be wrong.
_Avoid_: RAG, model memory, training data

**Knowledge Source**:
A documentation corpus prepared for Knowledge Retrieval. Initial Knowledge Sources cover Pika, Otter, Debian-family system behavior, Arch reference material, and basic GNU/Linux command usage.
_Avoid_: Random web scrape, training corpus, browser cache

**Curated Pika Knowledge Base**:
The vendored, reviewed Pika documentation corpus used as a Packaged Knowledge Source. It is not fetched from Wiki.js at install time and does not require shipping Wiki.js credentials.
_Avoid_: Live Wiki.js dump, token-backed runtime source

**Packaged Knowledge Source**:
A Knowledge Source shipped pre-indexed with Otter Assist because it is stable, redistributable, text-oriented, and directly useful for user support.
_Avoid_: Forum scrape, blog scrape, opportunistic web cache

**Knowledge Index**:
The packaged `.zidx` retrieval artifact consumed by the Assistant Service for one or more Packaged Knowledge Sources. In the initial workflow, Knowledge Index artifacts live in the `otter-assist` repository.
_Avoid_: Shared app database, user chat store

**Index Build**:
An offline packaging step that turns Packaged Knowledge Sources into Knowledge Indexes before installation.
_Avoid_: Background updater, live crawler, per-user index refresh

**UI Layout Layer**:
The baseline way Otter Shell surfaces describe layout, interaction regions, and visual structure consistently across apps. Existing direct drawing and widget code may remain as compatibility paths during migration, but new UI work should speak this model.
_Avoid_: Optional layout helper, experimental UI helper

**Surface Description**:
The public Zig expression of a screen, panel, popup, or widget tree: what appears, how it is arranged, which text it contains, and which interactions it exposes. App and widget authors write surface descriptions; rendering details remain below this boundary.
_Avoid_: Command list, draw buffer, manual paint routine

**Text System**:
The shared path that turns localized text into measured, ordered, shaped glyph runs for the CPU renderer. It covers translation keys, fallback font selection, CJK input/display, RTL ordering, complex script shaping, wrapping, truncation, and IME preedit placement.
_Avoid_: Raw glyph loop, ASCII text path, app-local text measurement

**Bidirectional Ordering**:
The part of the Text System that turns logical-order text into visual runs for mixed left-to-right and right-to-left content. It preserves editing/index mapping and must work per paragraph or line, not by reversing strings.
_Avoid_: RTL reversal, right-align hack

**Text Shaping**:
The part of the Text System that turns script runs and selected fonts into positioned glyphs, including contextual forms, ligatures, combining marks, advances, offsets, and text clusters.
_Avoid_: Glyph lookup, font rasterization, codepoint loop

**Terminal Rendering Boundary**:
The shared `otter-vte` layer that turns terminal cell grids into CPU-renderer command buffers, powerline/block primitives, custom cell glyphs, and shaped text commands. Apps own sessions and PTYs; terminal drawing belongs here so terminal views can be embedded without copying app internals.
_Avoid_: App-local terminal renderer, copied terminal draw loop

**Server-side Decoration**:
A compositor-owned visual frame for a managed window. In Otter's Hyprland integration, this means styling Hyprland's own decoration properties, not drawing an Otter surface or custom titlebar controls.
_Avoid_: SSD, Otter titlebar, client-side decoration

**Layout-managed Floating Window**:
A window presented as freely movable and resizable while remaining owned by the active layout. It may keep a freeform box or occupy a snap region, but it is not treated as Hyprland's separate floating mode.
_Avoid_: Actual floating window, Hyprland floating window, unmanaged float

**Snap Region**:
A named screen region occupied by a Layout-managed Floating Window, such as left half, right half, corner quarter, top, bottom, or maximized. A snapped window keeps its prior freeform box so leaving the Snap Region can restore that box.
_Avoid_: Fake tile, tile node, split tree

**Frame Box**:
The visual rectangle of a Layout-managed Floating Window, including titlebar and client content. Snap, maximize, and move operations use this box so titlebar and client content remain aligned.
_Avoid_: Client box, content box, decoration overlay box

**Plugin-managed Minimize**:
A minimize behavior implemented by the Hyprland integration instead of Hyprland's internal hidden state. The window leaves the visible workspace, keeps enough restore state to return, and remains identifiable to Otter components.
_Avoid_: Hidden window, compositor minimize, close-to-tray

**Minimize Workspace**:
A non-visible special workspace used as the holding area for Plugin-managed Minimize. Windows placed there are not closed or forgotten; they can be restored with their previous workspace and Frame Box.
_Avoid_: Dock minimized state, zango minimize, scratchpad window

**Titlebar Companion**:
A separate layer-shell process that draws interactive titlebars for Hyprland-managed windows and sends commands back through Hyprland's Lua dispatcher surface. It is not a compositor decoration and does not own layout state.
_Avoid_: Hyprland decoration, C++ decoration plugin, client-side titlebar

**Titlebar Drag**:
A pointer gesture on the Titlebar Companion that moves the Frame Box for a Layout-managed Floating Window. It may be backed by Native Window Move while the layout preserves snap and restore semantics.
_Avoid_: Client drag, content drag

**Native Window Move**:
Hyprland's own window movement dispatcher applied to the underlying managed window. It is the preferred transport for Titlebar Drag when it can keep layout state and Frame Box geometry coherent.
_Avoid_: Manual compositor reimplementation, fake pointer drag

**Decoration Theme Tokens**:
The existing Otter theme values that describe titlebar colors, button colors, titlebar height, button sizes, padding, and radius. Hyprland titlebar work consumes these tokens instead of creating a separate visual vocabulary.
_Avoid_: Hyprland-only titlebar theme, duplicate titlebar style, hard-coded titlebar colors

**Decoration Boundary**:
The split between native Hyprland window styling and Otter-drawn titlebar controls. Hyprland owns border, rounding, shadow, blur, opacity, and border colors; Otter owns titlebar background, title text, and buttons.
_Avoid_: Duplicate border renderer, fake compositor shadow, titlebar-as-Hyprland-decoration

## Example Dialogue

Dev: "Should the settings editor use the UI Layout Layer?"
Domain expert: "Yes. The UI Layout Layer is the standard model for complex and simple shell surfaces, not an optional helper for special cases."

Dev: "Should this settings tab build draw commands directly?"
Domain expert: "No. It should provide a Surface Description and let the UI Layout Layer handle layout, interaction regions, and rendering."

Dev: "Can this widget measure text by summing FreeType advances?"
Domain expert: "No. It should ask the Text System so localized, RTL, CJK, and shaped text use the same measurement path as rendering."

Dev: "Can RTL support reverse the UTF-8 string before drawing?"
Domain expert: "No. Bidirectional Ordering produces visual runs while preserving logical indexes for selection, cursor movement, and IME placement."

Dev: "Can font rendering choose one glyph per Unicode codepoint?"
Domain expert: "No. Text Shaping selects and positions glyphs for the script and font before the CPU renderer rasterizes them."

Dev: "Should another app copy `otter-term`'s cell renderer to show terminal output?"
Domain expert: "No. It should embed through the Terminal Rendering Boundary and pass app/session hooks into `otter-vte`."

Dev: "Can the Hyprland layout draw Otter titlebar buttons when server-side decorations are enabled?"
Domain expert: "No. Server-side Decoration means Hyprland owns the frame; Otter may choose styling, not draw controls."

Dev: "Should a freeform window in the Hyprland layout be toggled into Hyprland floating mode?"
Domain expert: "No. It is a Layout-managed Floating Window so the layout can preserve geometry and snap regions."

Dev: "Is a snapped half-screen window part of a tiling tree?"
Domain expert: "No. It occupies a Snap Region and can return to its prior freeform box."

Dev: "Should snap store the client content rectangle?"
Domain expert: "No. Snap stores the Frame Box so titlebar and client content move as one window."

Dev: "Does minimize require Hyprland's internal hidden flag?"
Domain expert: "No. Plugin-managed Minimize can move the window out of the visible workspace and restore it with its previous state."

Dev: "Is a minimized Hyprland window stored in the dock?"
Domain expert: "No. It lives in the Minimize Workspace until the Hyprland integration restores it."

Dev: "Should the Lua layout draw titlebar controls?"
Domain expert: "No. The Titlebar Companion draws controls; the Lua layout owns placement and command handling."

Dev: "Can dragging the titlebar move only the client content?"
Domain expert: "No. Titlebar Drag moves the Frame Box so the titlebar stays attached to the client content."

Dev: "Should titlebar movement reimplement Hyprland's own move behavior?"
Domain expert: "No. Use Native Window Move when it preserves the layout's Frame Box state."

Dev: "Should Hyprland titlebars define a separate color scheme?"
Domain expert: "No. They should consume Decoration Theme Tokens so Otter window chrome stays consistent."

Dev: "Should the Titlebar Companion draw compositor borders and shadows?"
Domain expert: "No. The Decoration Boundary keeps borders and shadows in Hyprland while Otter draws titlebar controls."

Dev: "Should Desktop Search assume a git repository or current code workspace?"
Domain expert: "No. Desktop Search is a shell feature for user-visible files and folders across configured Search Roots."

Dev: "Can Desktop Search index all of `$HOME` recursively by default?"
Domain expert: "No. Use XDG user directories, `$HOME/.config`, and direct `$HOME` children; broad home indexing needs explicit user configuration."

Dev: "Should one-level `$HOME` entries be handled as a recursive Search Root?"
Domain expert: "No. Direct `$HOME` children are shallow Path Search entries so Search Exclusions and memory limits stay predictable."

Dev: "Is Content Search the primary interaction?"
Domain expert: "No. Path Search is primary; Content Search is secondary and capped by file type, file size, and memory budget."

Dev: "Can the assistant search user files the same way it searches packaged docs?"
Domain expert: "No. User files are Desktop Search Tool territory and require explicit approval in the Assistant App."

Dev: "Should Desktop Search Tool approval be remembered per chat?"
Domain expert: "No. The first version supports per-call approval and an app-wide always-allow setting, not per-thread trust."

Dev: "Can Desktop Search Tool read full files after finding a match?"
Domain expert: "No. The first version returns only Path Search and Content Search results; full file reads would be a separate approved capability."

Dev: "Should the graphical assistant own web search and retrieval tools?"
Domain expert: "No. Those are Assistant Tools owned by the Assistant Service so other Otter Shell consumers can request them too."

Dev: "Should the Assistant App shell out to `otter-assistctl` for answers?"
Domain expert: "No. It talks to the Assistant Service through the Assistant Socket, similar to how Otter consumers talk to `otter-search`."

Dev: "Should every consumer hand-roll the Assistant Socket protocol?"
Domain expert: "No. Consumers use the shared Assistant Client so CLI and graphical behavior stay aligned."

Dev: "Should the Assistant Socket require its own auth token?"
Domain expert: "No. The first version relies on per-user runtime directory socket permissions, matching the local-user trust model used by Otter Search."

Dev: "Is the Assistant App the backend?"
Domain expert: "No. The Assistant App is the XDG toplevel chat surface; reusable assistant capability lives in the Assistant Service."

Dev: "Can the Assistant App draw the transcript directly like a one-off app?"
Domain expert: "No. The Assistant App must use the UI Layout Layer and Surface Description from the start; existing apps such as otter-monitor are lifecycle guides, not permission to add a legacy drawing path."

Dev: "Where should citations and tool metadata appear?"
Domain expert: "In the Assistant App inspector beside the transcript when there is room, and in a drawer on narrow surfaces."

Dev: "Can assistant answers render raw HTML?"
Domain expert: "No. Assistant Markdown excludes raw HTML and math, but supports tables, images, task lists, links, blockquotes, and Code Blocks."

Dev: "Should Markdown images require a click before any remote fetch?"
Domain expert: "No. Assistant Markdown may load Cached Remote Images, following Otter's existing external image cache behavior."

Dev: "Should Code Blocks use a generic monospace renderer only?"
Domain expert: "No. Code Blocks should use `zhl` highlighting when a language is known."

Dev: "Should the Assistant Service save every user's chat history?"
Domain expert: "No. Chat Threads are owned by the Assistant App; the Assistant Service only sees the messages included in a request."

Dev: "Can Chat Threads be saved as plain JSON because they are under the user's home directory?"
Domain expert: "No. Saved Chat Threads are Encrypted Chat Threads and should not be readable as plain text from the thread store."

Dev: "Should all Chat Threads live in one encrypted database?"
Domain expert: "No. Each Chat Thread is stored independently as Thread Events so backup, deletion, and corruption recovery stay simple."

Dev: "Should every assistant response regenerate the thread title?"
Domain expert: "No. A Thread Title starts from clipped first user text, then gets one Assistant Service suggestion unless the user renames it."

Dev: "Should Thread Title generation run the full assistant tool loop?"
Domain expert: "No. Thread Title generation is a separate Assistant Service request with Assistant Tools disabled."

Dev: "Should web search or Desktop Search run silently for every assistant request?"
Domain expert: "No. Networked and user-file Assistant Tools require approval unless the user has enabled app-wide always-allow; local time and date context may be included without a tool call."

Dev: "Should the Assistant App decide whether Pika Search or Knowledge Retrieval are globally available?"
Domain expert: "No. Assistant Tool defaults belong to the Assistant Service configuration; the Assistant App owns only UI preferences."

Dev: "Should Web Search and Desktop Search use different permission flows?"
Domain expert: "No. Both use Tool Approval, with separate app-wide always-allow settings when the user wants fewer prompts."

Dev: "Should the Assistant Service call back into the UI to ask permission?"
Domain expert: "No. It emits a Tool Approval requirement and resumes through an Approval Continuation."

Dev: "Should tool progress appear as assistant text?"
Domain expert: "No. Tool progress appears as Assistant Stream Events and UI timeline/status, not as generated prose."

Dev: "Should the Assistant Service keep the old `{message, stats}` JSON stream for new assistant consumers?"
Domain expert: "No. Assistant interactions use Event Stream Responses; the old JSON object stream can be removed if no current consumer requires it."

Dev: "Should tool execution details be mixed into the assistant's answer text?"
Domain expert: "No. Tool Stats are structured metadata returned beside the answer so UIs can show them without polluting the response."

Dev: "Should denied Tool Approval requests disappear from the final result?"
Domain expert: "No. Tool Stats records denied tool requests so the Assistant App can explain missing live or file data without adding permission noise to assistant prose."

Dev: "Should model speed only appear in logs?"
Domain expert: "No. Generation Stats such as tokens per second and time to first token should be visible in the Assistant App inspector or status area."

Dev: "Should normal Assistant App UI show the raw prompt sent to the model?"
Domain expert: "No. It should show a concise tool timeline, Tool Stats, and Generation Stats; raw prompts are not normal user-facing content."

Dev: "Should local time be exposed through a tool call?"
Domain expert: "No. The Assistant Service injects current local date, time, and timezone as request context."

Dev: "Can Web Results or Knowledge Sources tell the Assistant Service to ignore tool limits?"
Domain expert: "No. Tool Evidence is untrusted evidence, not instructions, and cannot change policy or request more tools."

Dev: "Should Otter Assist run only one preflight retrieval pass?"
Domain expert: "No. It uses a Bounded Tool Loop: fully featured enough for multi-step answers, but constrained so tool use cannot run indefinitely."

Dev: "Should the Assistant Service parse prose to decide tool calls?"
Domain expert: "No. Tool Control Turns use strict JSON with known actions and tool fields."

Dev: "Should the final answer prompt include every Tool Control Turn JSON blob?"
Domain expert: "No. The final answer sees compact Tool Evidence and citations; control JSON stays in Tool Stats or debug metadata."

Dev: "Should Otter Assist vendor Pika Search server code for web results?"
Domain expert: "No. The Web Search Tool should call Pika Search's JSON API when web access is granted."

Dev: "Should web search fetch and summarize every result page?"
Domain expert: "No. Web Results provide snippets and citations; deep page fetching is outside the first assistant scope."

Dev: "If a user asks for weather in Paris, should the assistant use the configured home weather location?"
Domain expert: "No. The Weather Tool uses an explicit requested place first, and falls back to configured Otter weather location only when no place is provided."

Dev: "Should Otter Assist shell out to `otter-weather` for weather answers?"
Domain expert: "No. The Weather Tool shares Otter weather library behavior, while `otter-weather` remains the human-facing CLI and cache updater."

Dev: "Should the assistant rely on its built-in model knowledge for Linux support?"
Domain expert: "No. Knowledge Retrieval should be encouraged for support answers because the local model's built-in knowledge is limited."

Dev: "Should the first Knowledge Sources be only Pika and Arch docs?"
Domain expert: "No. Pika is Debian-based, so Debian-family documentation and basic GNU/Linux command references belong in the initial Knowledge Sources too."

Dev: "Should installed Otter Assist use a Wiki.js token to fetch Pika Wiki pages?"
Domain expert: "No. Pika documentation enters Knowledge Retrieval as a Curated Pika Knowledge Base, not a token-backed runtime fetch."

Dev: "Can any useful troubleshooting page be shipped as a Knowledge Source?"
Domain expert: "No. Packaged Knowledge Sources must be stable, redistributable, text-oriented, and directly useful for support; transient pages belong behind web search."

Dev: "Should every assistant consumer open packaged indexes itself?"
Domain expert: "No. Knowledge Indexes are service data for the Assistant Service; shared code may live in Otter libraries, but consumers request retrieval through the service."

Dev: "Should curated source dumps be committed beside the Assistant Service code?"
Domain expert: "No. Curated source dumps may live in a local Otter Shell subdirectory during development; packaged `.zidx` Knowledge Index artifacts live in `otter-assist`."

Dev: "Can users add private Knowledge Indexes in the first assistant version?"
Domain expert: "No. Initial Knowledge Retrieval uses only packaged Knowledge Indexes."

Dev: "Should Otter Assist refresh Packaged Knowledge Sources in the background?"
Domain expert: "No. Packaged Knowledge Sources are prepared by an Index Build and installed as Knowledge Indexes; live or user-triggered refresh can come later."
