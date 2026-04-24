<!-- GENERATED FILE — do not hand-edit. Regenerate with the procedure below. -->

# Maintenance

This file is machine-maintained. Agents must never patch it incrementally — always regenerate it from scratch so every assertion is grounded in the actual tracked files.

## When to regenerate

Regenerate `MAINTENANCE.md` as part of any PR that adds, removes, or changes tracked files in this repo. The regeneration should be a commit in the PR branch, not a separate PR.

## How to regenerate

1. Run `git ls-files` to get the authoritative list of tracked files.
2. Read every tracked file. For each file, extract its purpose and key details.
3. Rewrite `MAINTENANCE.md` in its entirety. Preserve the two-section structure: this Maintenance header, then the Home Directory reference below.
4. Verify every claim against the actual file contents — do not carry forward stale descriptions.
5. Commit the updated `MAINTENANCE.md` alongside the other changes in the PR.

---

# Home Directory — ellistarn/home

This is Ellis Tarn's home directory, managed as a git repo (`github.com/ellistarn/home.git`). It tracks dotfiles, shell configuration, custom scripts, agent configs, and service definitions across two machines: a macOS laptop and an Amazon Linux dev desktop.

## Git Structure

The repo uses a **whitelist `.gitignore`** pattern: everything is ignored by default (`*`), then specific files and directories are explicitly unignored. To track a new file, add a `!path` entry to `.gitignore`.

- **Remote:** `ssh://git@github.com/ellistarn/home.git`
- **Branch:** `main`
- **Bootstrap:** `sh -c "$(wget https://raw.githubusercontent.com/ellistarn/home/main/bin/install-home.sh -O -)"`

The `.gitconfig` conditionally includes `.gitconfig-amazon` for any repo under `~/workspaces/`, switching identity and settings for Amazon work.

## Tracked File Categories

| Category | Files | Purpose |
|----------|-------|---------|
| Shell | `.zshrc`, `.tmux.conf`, `.p10k.zsh`, `.antigenrc`, `.condarc` | Zsh with Antigen plugin manager, Powerlevel10k theme, tmux |
| Aliases | `.aliases`, `.amazon.aliases`, `.kubectl.aliases` | General, Amazon tooling, and kubectl shorthand (~800 combinatorial k8s aliases) |
| Git | `.gitconfig`, `.gitignore`, `.gitignore.global`, `.gitconfig-amazon` | Identity (SSH signing), URL rewrites (HTTPS to SSH), conditional includes |
| Scripts | `bin/` | Custom tooling (see below) |
| Agent skills | `.agents/skills/` | Shared agent skills for design, implementation, instrumentation, code org, finish checklists, Krocodile |
| OpenCode | `.config/opencode/` | Global OpenCode config, custom agents (`agents/`), slash commands (`commands/`), skills |
| Claude Code | `.claude/` | Claude Code config, MCP servers, settings |
| Kiro | `.kiro/` | Kiro agent configs and settings |
| AWS | `.aws/config` | Two profiles using `fast-aws-creds` as credential_process (no static secrets) |
| Services | `.services/` | Caddy reverse proxy config, systemd units for caddy, code-server, opencode |

## Scripts (bin/)

| Script | Purpose |
|--------|---------|
| `git-gone` | Smart branch/worktree cleanup. Detects landed branches (ancestry check + squash-merge tree simulation), deletes clean+landed branches and their worktrees/remotes. `--stale` mode removes inactive branches past a time threshold (default 12h). Color-coded status output. |
| `wt` | Create or resume a **local** git worktree. `wt` (no args) creates `.worktrees/<MMDDTHHMM>-<RANDOM>` with matching branch, then launches `opencode`. `wt <name>` resumes an existing worktree. |
| `rwt` | Create or resume a **remote** worktree on the dev desktop via SSH. Translates local paths to remote equivalents. Opens cmux workspace with opencode. `rwt` (no args) lists existing remote worktrees. |
| `login.sh` | Amazon Midway authentication + SSH tunnel lifecycle. `--check` mode (called from `.zshrc`) does read-only validation. Normal mode force-refreshes auth and restarts the tunnel. |
| `fast-aws-creds` | Caching wrapper around `ada credentials print`. Caches in `/tmp/` for 15 minutes. Used as `credential_process` in `.aws/config`. |
| `fast-kube-creds` | Caching wrapper around `aws eks get-token`. Caches tokens for 10 minutes. Auto-detects cluster from kubeconfig. Self-installs as exec credential plugin. |
| `assume_role` | STS assume-role that writes temp credentials to `~/.aws/credentials [default]`. |
| `aws_account` | Prints current AWS account ID. |
| `install-home.sh` | Bootstrap: clone home repo into `~` on a fresh machine. |
| `setup/setup.sh` | Orchestrator: runs all `*.sh` scripts in `bin/setup/` in sorted order. |
| `setup/services.sh` | Syncs `.services/` configs to system locations (systemd units, Caddy config). Linux only. Tracks managed files, prunes orphans, restarts only on changes. |
| `setup/dev-tunnel.sh` | Sets up `*.etarn` local domain resolution via dnsmasq. macOS only. |

## Agent Configuration

### Shared Skills (`.agents/skills/`)

Six skills available to all agent tools (OpenCode, Claude Code, etc.):

| Skill | Purpose |
|-------|---------|
| `declaring-designs` | Checklist for well-formed design documents. Designs as control surface with obligation/judgment/scope zones. |
| `finish` | Completion checklist: rebase, design quality, implementation quality, validation, single commit, PR creation. |
| `reconciling-code-instrumentation` | Logging/observability guidance. ERROR (alerts), INFO (external effects, logged once after), DEBUG (why, off by default). Structured context at scope boundaries. |
| `reconciling-code-organization` | Code structure guidance. Finding and hardening boundaries by analyzing packages, imports, contracts. One level per invocation. |
| `reconciling-implementations` | Implementation quality: Correctness > Performance > Observability > Testing > Simplicity. Reconcile code against designs, surface tensions rather than silently resolving. |
| `using-krocodile` | Reference for Krocodile (kro), a Kubernetes composition system. `Graph` resources, node body keywords, CEL dependency expressions. 739-line comprehensive reference. |

### OpenCode Config (`.config/opencode/`)

- `opencode.json` — Global config: Bedrock Opus model, plan as default agent, MCP servers (builder-mcp, muse — both disabled), external directory permissions for `~/go/src/github.com/ellistarn/**`
- `agents/author.md` — Subagent for writing design documents. Read-only (no bash). Gathers context, models the story, writes the complete next version, then self-reviews against declaring-designs checklist.
- `commands/finish.md` — Slash command triggering the finish skill checklist.
- `AGENTS.md` — Global personal preferences (worktree conventions, communication style). Applied to every OpenCode session regardless of project.

## Dev Desktop Architecture

The setup spans macOS (laptop) and a Linux dev desktop (Amazon Cloud Desktop), connected via SSH tunnel.

```
macOS laptop                          Linux dev desktop
  *.etarn:9847  ──dnsmasq──>  127.0.0.1:9847  ──SSH tunnel──>  :9847
                                                                  │
                                                              Caddy reverse proxy
                                                                  │
                                              opencode.etarn  ──> :9000 (opencode serve)
                                              vscode.etarn    ──> :9001 (code-server)
                                              etarn           ──> static files
```

- **dnsmasq** resolves `*.etarn` to `127.0.0.1` (configured by `bin/setup/dev-tunnel.sh`)
- **SSH tunnel** forwards local port 9847 to dev desktop (managed by `bin/login.sh`)
- **Caddy** on the dev desktop routes by hostname (configured in `.services/caddy/Caddyfile`)
- **systemd** manages caddy, code-server, and opencode services (units in `.services/systemd/`)

## Shell Environment Highlights

- **Zsh** with Antigen, Oh My Zsh, Powerlevel10k
- **PATH** includes: `~/bin`, `~/.local/bin`, `~/.opencode/bin`, Go, Cargo, Bun, Python 3.14, `.toolbox/bin`
- **Identity:** GitHub user `ellistarn`, AWS account `767520670908`
- **Kubernetes:** KO_DOCKER_REPO points to ECR, KUBECONFIG merges local `./.kube/config` with `~/.kube/config`
- **Key aliases:** `c` = opencode, `q` = kiro-cli, `terraform` = tofu, `watch` = viddy
- **Shell functions:** `instanceid` (EC2 from k8s node), `ssmnode` (SSM into k8s node), `ecr_login`, `aws_login`

## Conventions

- **Worktrees:** Work happens in `.worktrees/<branch>`. Branch names follow `$(date +%m%dT%H%M)-$RANDOM-<task>`. The worktree directory name must equal the branch name.
- **`git-gone`** cleans up branches whose PRs have landed or gone stale.
- **Global gitignore** (`.gitignore.global`): Ignores `.DS_Store`, `.kiro/sessions/`, `.vscode`, `.terraform`, `.llama`, `.claude`, `.opencode`, `.worktrees` in all repos.
- **Git push auto-setup:** `autoSetupRemote = true` means `git push` on a new branch auto-creates the remote tracking branch.
- **URL rewrite:** All `https://github.com/` URLs are rewritten to `ssh://git@github.com/` in git config.

## Untracked but Notable Directories

These exist on disk but are not tracked in the home git repo:

| Directory | Contents |
|-----------|----------|
| `go/` | Go workspace (GOPATH). Projects under `go/src/github.com/ellistarn/`: karpenter, karpenter-provider-aws, kro, muse, kubernetes, kueue, hyperdrive |
| `workspaces/` | Amazon work projects (ark, EKS*, meshclaw, Scramble). Uses `.gitconfig-amazon` identity. Each is its own git repo. |
| `.beads/` | Beads issue tracker database (SQLite) |
| `.muse/` | Muse AI tool sessions and conversations |
| `.worktrees/` | Active git worktrees for the home repo |
| `tmp/` | Temporary files |
