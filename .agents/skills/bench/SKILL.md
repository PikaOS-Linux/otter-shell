---
name: bench
description: Run benchmarks for otter-conf or otter-desktop and compare results with poop
disable-model-invocation: true
---

# Benchmark Runner

Run and compare benchmarks for otter-shell components.

## Available Benchmarks

### otter-conf

Parser performance comparing otter-conf vs std.json vs zig-toml.

```bash
cd /home/ferreo/otter-shell/otter-conf/benchmarks && zig build bench
```

Compare with poop:
```bash
cd /home/ferreo/otter-shell/otter-conf/benchmarks && zig build bench
poop './zig-out/bin/bench-otter large 1000' './zig-out/bin/bench-json large 1000'
```

Size options: `small`, `medium`, `large`

### otter-desktop

SysInfo parsing and scanning benchmarks.

```bash
cd /home/ferreo/otter-shell/otter-desktop/benchmarks && zig build bench
```

Individual benchmarks:
```bash
zig build bench-parse    # /proc file parsing
zig build bench-scan     # device scanning
zig build bench-sysinfo  # full sysinfo collection
```

Generate test data:
```bash
zig build gen-testdata
```

## Workflow

1. Build benchmarks for the target component
2. Run benchmarks and capture baseline numbers
3. Make code changes
4. Rebuild and re-run benchmarks
5. Compare results using `poop` for statistical comparison
6. Report: metric, before, after, delta percentage

## Reporting

Present results as a table:

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Wall time | ... | ... | ...% |
| Instructions | ... | ... | ...% |
| Cache misses | ... | ... | ...% |

Flag any regression > 5% as a warning.
