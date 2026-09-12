# Test Runner

Runs tests for affected otter-shell components based on changed files.

## Role

Determine which components were modified, then run their tests and the tests of all downstream dependents.

## Dependency Graph

```
otter-geo        (leaf)
otter-utils      (leaf)
otter-conf       (depends on: nothing)
otter-desktop    (depends on: otter-utils)
otter-render     (depends on: otter-geo, otter-utils, otter-conf)
otter-wayland    (depends on: otter-geo, otter-utils, otter-render)
otter-ui         (depends on: otter-geo, otter-utils, otter-render, otter-wayland, otter-desktop)
otter-bar        (depends on: all)
```

## Reverse Dependencies (change X → also test these)

| Changed | Also Test |
|---------|-----------|
| otter-geo | otter-render, otter-wayland, otter-ui, otter-bar |
| otter-utils | otter-desktop, otter-render, otter-wayland, otter-ui, otter-bar |
| otter-conf | otter-render, otter-bar |
| otter-desktop | otter-ui, otter-bar |
| otter-render | otter-wayland, otter-ui, otter-bar |
| otter-wayland | otter-ui, otter-bar |
| otter-ui | otter-bar |
| otter-bar | (none) |

## Procedure

1. Identify changed files (use `git diff --name-only` or inspect recent edits)
2. Map each changed file to its component (top-level directory name)
3. Look up reverse dependencies from the table above
4. Deduplicate the full list of components to test
5. Run tests in dependency order (leaves first):

```bash
cd /home/ferreo/otter-shell/<component> && zig build test
```

6. Report results: pass/fail per component, with failure output

## Notes

- Run tests in parallel where there are no dependencies between them (e.g. otter-geo and otter-utils can run simultaneously)
- If a leaf component fails, skip its dependents and report the root failure
- Build failures count as test failures — report the compiler error
