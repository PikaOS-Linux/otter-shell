# otter-shell workspace

Thin git root over the Otter Shell package repos (git submodules). Package remotes stay canonical for day-to-day commits and releases.

## Clone (cloud / fresh machine)

```bash
git clone --recurse-submodules git@ssh.pika-os.com:otter-shell/otter-shell.git
# if already cloned without submodules:
git submodule update --init --recursive
```

## Local package work (unchanged)

```bash
cd otter-bar
# edit, zig build -Doptimize=ReleaseFast test, commit, push to package origin
```

Root pin need not move for every package commit.

## Bump workspace pins

```bash
./scripts/sync-workspace.sh --remote
git add -A
git status   # review submodule SHA moves
git commit -m "chore: bump workspace pins"
```

## Layout notes

- `.agents/skills/` is the skill source of truth; `.claude/skills` is a symlink to it
- Cursor-only: `.cursor/skills/verify-otter-settings/`
- Agent guidance: `AGENTS.md`, `CLAUDE.md`, `CONTEXT.md`
