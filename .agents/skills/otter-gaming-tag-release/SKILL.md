---
name: otter-gaming-tag-release
description: Tag a new Otter Bench release. Pins otter-bench's build.zig.zon to the otter-* library tags that already exist, tags and pushes otter-bench, then restores local path deps.
user-invocable: true
argument-hint: <version e.g. 0.1.0>
---

# Release Tagging for Otter Bench

Tag `otter-bench` for release version `v$ARGUMENTS`.

## How this differs from `tag-release`

`tag-release` tags the whole shell — 43 repositories, level by level, because
each library's tag has to exist before its dependents can pin it.

**This skill tags exactly one repository: `otter-bench`.** It does not tag,
version, or commit to any `otter-*` library. Otter Bench releases on its own
cadence and consumes whichever library tag is already published.

If a library genuinely needs a new release, run `tag-release` for the shell
first and then run this skill. Never tag a library from here — a library tag
that exists only because Otter Bench needed one is a tag the shell did not
agree to.

## Pre-flight

1. Verify the version argument is provided (e.g. `0.1.0`). Abort if missing.
2. Verify `v$ARGUMENTS` does **not** already exist on `otter-bench`. Abort if it does.
3. Verify `otter-bench` has no uncommitted changes. If it has, commit them with
   descriptive messages and push before proceeding.
4. Verify `otter-bench` is not ahead of `origin/main`. Push first if it is.
5. **Resolve the library tag.** Read the latest tag from each library
   `otter-bench` depends on:

   ```
   cd ../<lib> && git tag --sort=-v:refname | head -1
   ```

   For the libraries listed below, confirm they are all on the **same** tag.
   If they are not, stop and report the disagreement rather than picking one —
   a mixed set means the shell is mid-release and Otter Bench should not pin
   into the middle of it.

   Call the agreed tag `LIB_VERSION`.

## Otter Bench's internal dependencies

Derive these from `otter-bench/build.zig.zon` rather than trusting the list;
it is a checklist, not the source of truth. Every `.path = "../otter-*"` entry
must be converted.

| Dependency | Pinned at |
|---|---|
| otter_geo | `LIB_VERSION` |
| otter_utils | `LIB_VERSION` |
| otter_conf | `LIB_VERSION` |
| otter_render | `LIB_VERSION` |
| otter_wayland | `LIB_VERSION` |
| otter_theme | `LIB_VERSION` |
| otter_ui | `LIB_VERSION` |
| otter_desktop | `LIB_VERSION` |

Non-internal dependencies (zigimg, freetype, harfbuzz, zeit, uucode and any
vendored path) are left exactly as they are.

## Process

### 1. Fetch each library hash at its existing tag

For each dependency above:

```
zig fetch "git+https://git.pika-os.com/otter-shell/<lib>.git#v<LIB_VERSION>"
```

Use a 60-second timeout; the git server can be slow. Store each returned hash.

**Do not tag anything here.** These tags already exist — you are reading them,
not creating them.

### 2. Pin otter-bench

a. Update the top-level `.version` in `otter-bench/build.zig.zon` to
   `$ARGUMENTS` (no leading `v`).
b. Replace every `.path = "../otter-*"` with the URL+hash form:

   ```zig
   .otter_foo = .{
       .url = "git+https://git.pika-os.com/otter-shell/otter-foo.git#v<LIB_VERSION>",
       .hash = "<hash from zig fetch>",
   },
   ```

   Note the URL carries `LIB_VERSION`, **not** `$ARGUMENTS`. Mixing them up
   produces a tag that cannot resolve, and it will not fail until someone
   tries to build from the tag.
c. Verify: no `.path = "../otter-` remains, `.version` is `$ARGUMENTS`, and
   every URL carries `LIB_VERSION`.
d. **Build it.** `zig build -Doptimize=ReleaseFast` must succeed against the
   pinned dependencies before anything is tagged. A tag that does not build is
   worse than no tag.
e. Commit: `git add build.zig.zon && git commit -m "build: pin libraries at v<LIB_VERSION> for v$ARGUMENTS"`

### 3. Tag and push

```
cd otter-bench && git tag v$ARGUMENTS && git push && git push origin v$ARGUMENTS
```

### 4. Restore local path deps

- Replace every URL+hash entry back to `.path = "../otter-*"`
- Leave external dependencies unchanged
- **Keep** `.version` at `$ARGUMENTS` — do not revert it
- Build once more to confirm the restored tree still compiles
- Commit: `git add build.zig.zon && git commit -m "build: restore local path deps after v$ARGUMENTS tagging"`
- Push

## Then update the packaging repository

`otter-gaming-utils` is what turns the tag into `.deb`s. After tagging:

1. Edit `otter-gaming-utils/main.sh`:
   - `VERSION="$ARGUMENTS"`
   - `LIB_VERSION="<LIB_VERSION>"` — only if the library pin moved
2. Add a `debian/changelog` entry for `$ARGUMENTS-1`, distribution `pika`.
3. Commit and push `otter-gaming-utils`.

The two version numbers in `main.sh` are independent by design. Bumping Otter
Bench does not require touching the libraries.

## Important rules

- The workspace root (`/home/ferreo/otter-shell/`) is a thin submodule workspace. Each
  subfolder is independent.
- Never add Co-Authored-By lines to commits.
- `zig fetch` timeout should be 60000ms.
- Never tag an `otter-*` library from this skill.
- Print a summary at the end: the Otter Bench tag, the library tag it pinned,
  and whether `otter-gaming-utils` was updated.
