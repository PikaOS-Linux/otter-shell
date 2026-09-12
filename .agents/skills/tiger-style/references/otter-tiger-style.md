# Otter Tiger Style Checklist

Source: https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md

Use this as a practical Otter Shell checklist. Preserve project rules from
`/home/ferreo/otter-shell/AGENTS.md`: Zig 0.16.0 style, surgical changes,
data-driven design, branchless hot paths where possible, and performance concerns
called out before merging.

## Priority

1. Safety.
2. Performance.
3. Developer experience.

Readability matters because it supports those goals. Do not churn readable code
for style points when safety and performance are unchanged.

## One Component Per Pass

- Treat each `otter-*` directory as an independent repo boundary.
- Work on one component unless user explicitly asks for a coordinated batch.
- Report findings and action plan before implementation.
- Do not edit code unless user gives explicit consent after the action plan.
- If user asks for review only, do not implement fixes.
- For whole-ecosystem alignment, process dependencies before dependents.
- Keep unrelated old violations as deferred findings unless touched code makes them relevant.

## Safety

- Prefer simple, explicit control flow.
- Avoid recursion. If recursion is unavoidable, prove and assert a small bound.
- Put a fixed upper bound on loops, queues, buffers, caches, and retries.
- Assert intentionally infinite loops, usually event loops.
- Use explicit integer widths for stored data, protocol fields, indexes with
  stable limits, and serialized formats.
- Use `usize` where Zig and std APIs require sizes, slice indexes, allocation
  sizes, or pointer-width arithmetic.
- Assert function preconditions, postconditions, and invariants with `std.debug.assert`.
- Split compound assertions into one assertion per fact.
- Assert both positive and negative space around validation boundaries.
- Assert relationships between comptime constants and struct sizes where assumptions matter.
- Handle all errors. Avoid `catch unreachable` unless invariant is local,
  obvious, and asserted nearby.
- State invariants positively. Prefer `if (index < length)` over negated bounds checks.
- Split complex boolean conditions when separate cases need independent reasoning.
- Keep variables in smallest useful scope.
- Calculate values close to use to avoid place-of-check/place-of-use gaps.
- Keep functions at or below 70 lines for new or touched code. Split by
  preserving one owner for control flow and moving branch-light work to helpers.

## Memory And Lifetime

- Prefer allocation during initialization.
- Avoid allocation, free, resize, and string formatting in draw paths, render hot
  paths, input handlers, protocol dispatch loops, D-Bus message drains, and
  config parse inner loops.
- Use `BoundedArray`, fixed buffers, arenas for one-shot apps, and explicit cache
  capacities when limits are known.
- Keep heap allocation in long-running daemons deliberate and visible. If runtime
  allocation remains, explain why fixed storage is worse.
- Construct large or immovable structs in place with an out pointer when that
  avoids copies or lifetime confusion.
- Pass types larger than 16 bytes as `*const` when they are not meant to be copied.
- Keep allocation and deallocation visually grouped.

## Performance

- Sketch cost before changing hot paths: network, disk, memory, CPU; bandwidth and latency.
- Optimize slow resources first after accounting for frequency.
- Batch work instead of reacting directly to every external event.
- Separate control plane from data plane where practical.
- Prefer predictable data access and data-driven tables over branch-heavy dispatch.
- Extract hot loops into small functions with primitive arguments when it helps
  register use and human review.
- Flag any change likely to hurt latency, RSS, allocation count, cache behavior,
  or draw throughput.
- Run benchmarks when touching parser, renderer, desktop scanning, theme
  generation, or other measured code.
- Look for useful `comptime`, SIMD, and branchless arithmetic in hot paths.
  Require a clear hot-path reason before adding complexity.

## Zig Review Additions

- Enforce a 750-line limit for production Zig code.
- Exclude dedicated test files and embedded `test` blocks from this cap.
- If tests live inside production files, count only the production code and
  recommend a split only when production logic breaches the cap.
- Prefer Zig's file-as-struct/module model: cohesive files, top-level
  declarations, and explicit data flow.
- Avoid giant manager structs, nested type sprawl, and files that mix unrelated
  responsibilities.
- Hoist imports to the top of the file. Inline imports are acceptable only in
  test blocks or rare local comptime isolation with a clear reason.
- Remove meaningful duplication. Add a shared helper only when repeated behavior
  is real and the helper does not hide intent.
- Favor Zig-native APIs and implementation.
- Isolate C interop at platform or library boundaries and justify broad C usage.
- Review RSS, allocation frequency, arena lifetime, ownership transfer, cleanup
  on error, cache bounds, and long-running daemon behavior.
- Ask for sensible tests: edge cases, allocation failure paths, parse/format
  round trips, ownership cleanup, and state transitions.

## Naming And Layout

- Use `snake_case` for functions, variables, and file names.
- Avoid abbreviations except tiny primitive variables in very local math or sort
  code.
- Put units and qualifiers last, most significant first: `latency_ms_max`,
  `size_bytes`, `index_next`.
- Distinguish `index`, `count`, and `size` in names and conversions.
- Use matching-length names for symmetric values when practical, such as
  `source` and `target`.
- Prefix callback/helper names with caller context when it clarifies call history.
- Put callbacks last in parameter lists.
- Use options structs when arguments of the same primitive type can be swapped.
- Put important declarations near top. In structs, prefer fields, nested types,
  then methods.
- Keep nested types top-level when they become complex.
- Comments explain why and how, not what obvious code does. Use complete sentence
  comments for standalone comments.

## Format

- Run `zig fmt`.
- Keep lines at or below 100 columns.
- Use 4-space indentation.
- Add braces to multiline `if` statements.
- Use explicit library options at call sites instead of relying on defaults when
  defaults matter for correctness or performance.
- Use `@divExact`, `@divFloor`, or a named `div_ceil` helper when rounding behavior matters.

## Tests

- Test valid and invalid inputs.
- Test transitions from valid to invalid state.
- Test error handling paths.
- Add paired tests for paired assertions when behavior crosses a boundary, such as
  encode/decode, parse/serialize, acquire/release, or read/write.
- Keep tests focused on the component under review.

## Dependencies

Otter policy differs from TigerBeetle's zero-dependency policy.

- Prefer no new dependency.
- Accept a dependency only when it is clearly needed for protocol compatibility,
  platform integration, security, or a domain engine that is too costly or risky
  to own.
- Before adding a dependency, document:
  - why stdlib or existing Otter code is insufficient
  - expected build, runtime, supply-chain, and maintenance cost
  - whether it can be optional at compile time
  - why vendoring, a tiny local implementation, or deleting the feature is worse
- Do not remove existing dependencies during a style pass unless user asked for
  that migration.
- Do not add dependencies for small scripts, parsing convenience, formatting, or
  one-off tooling.
- Prefer Zig tooling for repo scripts. Shell is acceptable only when it is already
  project convention or the script is strictly environment glue.

## Review Heuristics

Classify findings:

- Must fix now: correctness, safety, unbounded work, hot-path allocation, error
  swallowing, dependency risk.
- Fix while touched: function length, naming, nearby assertions, line length,
  comments that block understanding.
- Defer: broad historical style drift outside target component or unrelated public API cleanup.

End every implementation pass with verification evidence or a clear blocker.

## Consent Gate

- Audit first.
- Report prioritized findings with exact files and lines when possible.
- Provide a concrete action plan and verification plan.
- Stop before edits and ask for explicit consent.
- After consent, implement only approved scope.
- If new findings appear during implementation, report them and ask before expanding scope.
