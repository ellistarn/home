---
description: Run when a task is done — squash, push, PR, review, design check
---

## Checklist

- [ ] Muse approves the change — `muse ask --new` with the diff and relevant context. If the muse has actionable comments, address them and re-consult with the updated diff. Repeat until the muse responds with no actionable comments.
- [ ] Single commit with a message that matches the change (squash if needed)
- [ ] PR title and body match the landed diff
- [ ] Declarative designs in `designs/` are not violated
- [ ] Declarative designs are updated for new concepts

## Report

Print pass/fail for each item, the PR url, and details for failures.
"Run `/finish` again" if unresolved, or "Ready to merge" if clean.
