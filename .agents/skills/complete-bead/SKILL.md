---
name: complete-bead
description: Complete a bead. Load when dispatched with a bead ID.
---

# Complete Bead

You were dispatched with a bead ID. Your scope is exactly what the bead describes — 
nothing more, nothing less.

## Workflow

1. **Read the bead:** `bd show <id>`
   - The description is your contract. Do exactly what it says.

2. **Read dependencies:** For each dependency listed in the bead, run `bd show <dep-id>`.
   The close reason of a dependency is its output value. Use these values as your inputs.

3. **Do the work.** Stay within the scope of this bead.

4. **Record narrative:** `bd comment <id> "what you did and why"`
   - Comments are the story of how the work happened. Write them for someone
     reconstructing your reasoning later.

5. **Close with output:** `bd close <id> --reason="<result>"`
   - The close reason is the bead's output. It must contain the concrete result —
     a value, a file path, a verdict — not a summary of activity.
   - Other beads that depend on this one will read your close reason as their input.

6. **If blocked:** `bd update <id> --status=blocked --notes="what's missing"`

7. **If you discover new work:** `bd create --title="..." --description="..."`
   - Do not do the new work yourself. The orchestrator will dispatch it.

## Rules

- Never work outside your bead's scope.
- Never call `bd ready` — the orchestrator owns the ready loop.
- Close reason is output, comments are narrative. Don't conflate them.
