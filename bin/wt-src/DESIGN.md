# `wt` — Worktree Session Manager

## Problem

Multiple AI agents working on the same repository collide -- they edit the same
files and corrupt each other's git state. Git worktrees solve this: each agent
gets an isolated working copy on its own branch, confined to its own directory.
OpenCode enforces the boundary -- given a directory, it stays in it.

Agents run for minutes or hours, and the laptop closes. Local processes die. Work
must survive beyond the laptop. This requires a persistent remote environment: an
OpenCode server on a dev desktop that runs continuously, with sessions that outlive
any client connection.

The developer thinks in worktrees, not sessions, ports, or connection strings.
"Show me everything in flight. Attach to that one." `wt` binds git worktrees to
OpenCode sessions -- locally and remotely -- and makes creating, listing, and
resuming trivial.

## Model

A **worktree** is a git worktree at `<repo>/.worktrees/<name>`, where `name`
equals the branch name. The worktree directory is the primary key. Worktrees are
created per unit of work and cleaned up separately when the branch lands.

A **session** is an OpenCode conversation bound to a worktree directory. Sessions
persist on the server, carry a title (auto-generated from the first prompt), a
status (idle/busy), and full message history. A worktree can have multiple
sessions; the most recent is attached by default. Session lifecycle (creating new
sessions, forking) is managed from within OpenCode, not by this tool.

The **OpenCode server** is a persistent process on the dev desktop. One server
hosts all worktrees across all repos. Every API endpoint accepts a `directory`
parameter to scope requests to a specific worktree. TUI clients are stateless --
they re-fetch everything on connect.

## Topology

### Local

OpenCode runs with its embedded server. The worktree and session live on the
laptop. Sessions do not survive laptop close.

```
wt
└── opencode              # in <repo>/.worktrees/<name>
```

### Remote

The worktree lives on the dev desktop, created over SSH. A persistent OpenCode
server manages the session. The TUI runs locally, connecting to the remote server
through an SSH tunnel.

```
laptop                                  dev desktop
  wt -r ~/go/src/.../kro ──SSH──>         git worktree add ...
                                                │
  opencode attach ────tunnel────────> opencode serve
    --dir <remote worktree path>
```

Sessions survive laptop close. On reattach, the TUI reconnects and loads the full
session state, including any work the agent completed while disconnected.

## CLI

### `wt [name]`

Create or resume a worktree.

- No args: create a new worktree in the current repo. Attach.
- With `name`: resume `<repo>/.worktrees/<name>`. Attach.

Attach: `opencode --continue` in the worktree directory.

### `wt -r <path> [name]`

Create or resume a remote worktree.

- `path` identifies the repo as a local-style path
  (e.g., `~/go/src/github.com/ellistarn/kro`), translated to the remote
  equivalent.
- Without `name`: create a new worktree. Attach.
- With `name`: resume existing worktree. Attach.

Attach: query the OpenCode server for the most recent session in the worktree,
then `opencode attach` to the remote server with the worktree directory and
session ID.

### `wt ls`

List all worktrees and their session status. Shows both local (current repo) and
remote (all repos on the dev desktop). If the remote is unreachable, shows local
only.

```
LOCAL
  WORKTREE          STATUS   TITLE
  0423T1600-4419    idle     Refactor config parser

REMOTE
  WORKTREE          REPO          STATUS   TITLE
  0423T1430-12847   .../kro       busy     Fix auth handler validation
  0422T0900-9182    .../karp      idle     Add node pool autoscaling
  0421T1100-5531    .../ark       -        -
```

## Reconnection

1. Laptop opens. SSH tunnel restarts.
2. `wt ls` shows everything in flight.
3. `wt -r ~/go/src/.../kro 0423T1430-12847` resumes.

## Assumptions

- An SSH tunnel to the dev desktop is established and maintained externally.
- The OpenCode server runs persistently on the dev desktop, managed externally.
- Worktree cleanup is handled externally.

## Implementation

Go binary. Shells out to `ssh` for remote git operations and to `opencode` for
TUI attachment. Talks to the OpenCode server via `net/http` for session discovery.
Single `main` package.

## Scoped Out

- Worktree cleanup.
- OpenCode server lifecycle.
- SSH tunnel management.
- Auto-reattach on laptop wake.
- Session lifecycle (new, fork). Managed from within OpenCode.
- Multiple remote hosts.

## Rejected Alternatives

**Bash** — JSON parsing for the OpenCode API requires external tooling. Go gives a
static binary with native HTTP and JSON support.

**cmux SSH for remote TUI** — The TUI runs on the dev desktop, viewed through a
forwarded terminal. Breaks on disconnect. `opencode attach` runs the TUI locally
and reconnects cleanly.

**Server per worktree** — Port management overhead. The OpenCode server's
`directory` parameter handles multi-project in one process.

**Separate local/remote tools** — Same workflow, different transport. One tool with
a `-r` flag.
