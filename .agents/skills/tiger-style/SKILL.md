---
name: tiger-style
description: >-
  Align one Otter Shell library or app with TigerBeetle-inspired engineering
  style and Otter's Zig code review rules.
---

# Tiger Style

## Overview

Run this skill on one Otter Shell component at a time. Optimize for safety first, performance
second, developer experience third. Default mode is audit and planning only.

Do not edit code while using this skill unless the user gives explicit consent after seeing
findings and an action plan. Consent must be a direct user message such as "apply this plan" or
"fix these findings"; do not infer consent from a broad request like "align the ecosystem".

Use the source checklist in `references/otter-tiger-style.md`. It distills TigerBeetle's
`TIGER_STYLE.md` for Otter Shell and overrides TigerBeetle's zero-dependency rule with Otter's
policy: prefer no new dependency unless the need is clear, measured, and cheaper than owning the
code. It also incorporates the existing `zig-code-review` skill's review rules.

## Workflow

1. Select exactly one component, usually a directory with `build.zig` under
   `/home/ferreo/otter-shell`.
   If user asks for the whole ecosystem, create an ordered checklist and process one component per
   pass.
2. Read `references/otter-tiger-style.md` before auditing.
3. Inspect component boundaries:
   - `build.zig`, `build.zig.zon`
   - public API files and hot paths under `src/`
   - tests and benchmarks relevant to touched code
4. State audit success criteria:
   - style gaps identified with file and line references where possible
   - action plan split into small implementation steps
   - verification command selected for each step
5. Audit for high-impact gaps before cosmetic gaps:
   - unbounded loops, queues, recursion, or event reactions
   - allocations in draw, event, parse, render, or D-Bus hot paths
   - missing assertions around indexes, lengths, lifetimes, and protocol states
   - confusing integer units or index/count/size conversions
   - branch-heavy data paths that can be data-driven
   - dependencies or tools not justified by a clear need
   - oversized files, weak module boundaries, duplication, inline imports, broad
     C interop, and ownership/RSS risks
6. Report findings and action plan before implementation. Stop and ask for consent.
7. If consent is given, make surgical edits only. Do not do repo-wide cleanup while processing one
   component. If user asked for review only, do not edit files.
8. Update tests, benchmarks, README, or AGENTS.md only when changed behavior or public guidance
   requires it.
9. Run verification from the component directory after edits:
   - `zig fmt --check .`
   - `zig build test`
   - component-specific benchmarks when performance-sensitive code changed
10. Report changed files, verification, remaining risks, and deferred cross-component work.

## Discovery Commands

Use `rg` first.

```bash
cd /home/ferreo/otter-shell/<component>
git status --short
files=$(rg --files -g '*.zig')
wc -l $files
rg -n \
  "TODO|FIXME|HACK|XXX|@panic|catch unreachable|unreachable|while \\(true\\)" \
  src build.zig build.zig.zon
rg -n \
  "std\\.heap|ArrayList|HashMap|alloc\\(|create\\(|destroy\\(|free\\(|defer|errdefer" \
  src build.zig build.zig.zon
rg -n "@import\\(|@cImport|extern|linkSystemLibrary|linkLibrary" build.zig src
rg -n "\\.url|\\.path" build.zig.zon
rg -n 'test "' src
awk 'length($0) > 100 { print FILENAME ":" FNR ":" length($0) }' $files
```

Use command output as leads, not proof. Exclude dedicated test files and embedded `test` blocks
from the 750-line production-code cap before flagging oversized files.

## Component Order

Prefer dependency order for ecosystem-wide work:

```text
otter-geo, otter-utils
otter-conf, otter-render, otter-desktop, otter-wayland, otter-theme, otter-config-types
otter-ui
otter-bar, otter-launcher, otter-dock, otter-notifications, otter-wallpaper, otter-osd,
otter-jade, otter-logout, otter-polkit, otter-lock, otter-greeter, otter-idle,
otter-settings, otter-term, otter-screenshot, otter-theme-gen
```

If the workspace has additional `otter-*` directories with `build.zig`, include them after checking
their dependency position.

## Report Format

Before edits, always report:

```text
Target: <component>
Goal: <specific style alignment>
Findings:
- [P1/P2/P3] <file:line> <risk and why it matters>
Action Plan:
1. <small edit or refactor step>
2. <test/benchmark/doc step>
Verification Plan:
- <commands to run after consented edits>
Deferred: <known issues intentionally left for another component/pass>
Consent Needed: Reply with explicit approval before code edits.
```

For review-only work, lead with severity-ordered findings using exact file and line references,
then list split-up implementation tasks and residual risk.

After consented edits, report:

```text
Target: <component>
Changed: <files>
Verification: <commands and result>
Deferred: <known issues intentionally left for another component/pass>
```

Do not claim alignment unless verification ran or the blocker is reported.
