# Agent helpers for Gitea SoT (Otter Shell)

Small bash wrappers so Cloud Agents follow Howard's conventions without using GitHub as the source of truth.

| Script | Purpose |
| --- | --- |
| `gitea-ssh-bootstrap.sh` | Decode SSH secrets → `~/.ssh`, export `GIT_SSH_COMMAND` |
| `git-identity-ferreo.sh` | Set author/committer to `ferreo`, disable Cursor co-author hook |
| `commit.sh` | `git commit` with ferreo identity + `commit.gpgsign=false` |
| `default-branch.sh` | Detect `main` vs `master` (`.gitmodules` → symref → ls-remote) |
| `new-branch.sh` | Create `fer/<slug>` from package default base |
| `push-package.sh` | Push `fer/*` branch to Gitea `origin` only |
| `update-parent-pin.sh` | Bump parent submodule pin; commit as ferreo |
| `gitea-pr.sh` | Create/comment/review Gitea PRs (needs `GITEA_TOKEN`; CF caveat) |

Typical flow:

```bash
./scripts/agent/gitea-ssh-bootstrap.sh --check
source "${XDG_RUNTIME_DIR:-/tmp}/otter-gitea-ssh.env"
./scripts/agent/git-identity-ferreo.sh
./scripts/agent/new-branch.sh otter-bar fix-widget
# edit…
./scripts/agent/commit.sh -am "fix: …"
./scripts/agent/push-package.sh otter-bar
./scripts/agent/gitea-pr.sh create --repo otter-bar --head fer/fix-widget --title "fix: …"
```

See Project store plan: `docs/agent-gitea-helpers.md`.
