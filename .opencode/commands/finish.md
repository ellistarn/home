---
description: Run when a task is done — squash, push, PR, review, design check
subtask: true
---

Work is in the active worktree under `.worktrees/`. Find it, its branch, and its PR.

## Checklist

- [ ] Single commit with a message that matches the change (squash if needed)
- [ ] PR title and body match the landed diff
- [ ] Code reviewed (re-read the diff in a fresh context)
- [ ] Declarative designs in `designs/` are not violated
- [ ] Declarative designs are updated for new concepts

## Report

Print pass/fail for each item, the PR url, and details for failures.
"Run `/finish` again" if unresolved, or "Ready to merge" if clean.
