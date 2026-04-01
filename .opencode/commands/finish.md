---
description: Run when a task is done — squash, push, PR, review, design check
subtask: true
---

Execute this checklist. Parallelize with subagents where possible. Resolve issues yourself and ask
the user only if a judgment call is needed.

## Checklist

- [ ] Single commit with a message that matches the change
- [ ] Ensure the PR title and body match the change
- [ ] Code is reviewed in a fresh context window
- [ ] Declarative designs are not violated by new changes
- [ ] Declarative designs are updated as needed for new concepts

## Report

Print the checklist with pass/fail status for each item, the PR url, and details for any failures.
End with: "Run `/finish` again" if there are unresolved findings, or "Ready to merge" if clean.
