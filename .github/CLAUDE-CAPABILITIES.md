# Claude capability workflows

Cloud Claude Code sessions reach GitHub through an egress proxy that only
allows repo-scoped API paths (`repos/{owner}/{repo}/...`) on repos granted to
the Claude GitHub App. Account-level operations — creating repos, managing
installations, anything under `/user/...` — are blocked regardless of what
token the session holds.

The workaround: GitHub Actions runners are outside that proxy. Workflows in
this directory act as **capabilities** Claude can invoke via
`workflow_dispatch`, executing with the `GH_ADMIN_TOKEN` secret.

## Setup (one time)

1. Create a PAT: classic with `repo` scope (add `delete_repo` if desired), or
   fine-grained with All repositories + Administration: write + Contents: write.
2. Add it as an Actions secret named `GH_ADMIN_TOKEN` in this repo
   (Settings -> Secrets and variables -> Actions).

## Capabilities

| Workflow | Purpose |
| --- | --- |
| `create-repo.yml` | Create a repo under your account; optionally grant the Claude app access to it |
| `gh-admin.yml` | Run an arbitrary `gh` command with the admin PAT (escape hatch) |

## How Claude uses these

From any session with access to this repo, Claude dispatches a workflow
(GitHub MCP `actions_run_trigger`), then polls the run and reads the job log /
step summary for the result. Only accounts with write access to this repo can
dispatch them, and every invocation is auditable in the Actions run history.
