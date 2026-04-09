---
description: Run when a task is done — squash, push, PR, review, design check
---

## Checklist

- [ ] PR is rebased to the latest commit on the appropriate remote branch
- [ ] Change has been manually validated in a development environment
- [ ] Single commit with a message that matches the change (squash if needed)
- [ ] PR title, body, and comments match the landed diff
- [ ] Declarative designs in `designs/` are not violated
- [ ] Declarative designs are updated for new concepts
- [ ] Muse approves the change — `muse ask --new` with the diff and relevant context. If the muse has actionable comments, address them and re-consult with the updated diff. Repeat until the muse responds with no actionable comments.

## Report

Print pass/fail for each item, the PR url, and details for failures.
"Run `/finish` again" if unresolved, or "Ready to merge" if clean.
