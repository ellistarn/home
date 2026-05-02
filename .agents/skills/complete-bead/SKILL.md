# Complete Bead

You were dispatched with a bead ID. This is your workflow:

1. Read the bead: `bd show <id>`
2. Do the work described
3. Record what you did: `bd comments add <id> "..."`
4. Close it: `bd close <id>`
5. If you discover new work, create a bead: `bd create --title="..." --description="..."`
6. If you're blocked, update status: `bd update <id> --status=blocked --notes="..."`

Return status: `closed`, `blocked`, or `error`.
