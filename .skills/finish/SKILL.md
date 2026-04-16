---
name: finish
description: Completion checklist. Load before declaring any task complete.
---

# Finish

Before work is declared complete, verify every item. Items that can be verified
programmatically, verify. Items that require human confirmation, ask.

## Checklist

- [ ] **Rebased** — PR branch is rebased to the latest commit on the target remote branch.
- [ ] **Designs updated** — Design gaps and proposed updates have been reviewed by the human.
- [ ] **Implementation Quality** — If implementing, load reconciling-implementations and execute the checklist
- [ ] **Design Quality** - If designing, load declaring-designs and execute the checklist
- [ ] **Validated** — The change works correctly in a development environment, if applicable.
- [ ] **Committed** — Branch has a single commit. The message summarizes the change clearly — show not tell for perf improvements, logging changes, or anything measurable.
- [ ] **PR created** — A pull request exists for this branch. Title and body match the commit message.
- [ ] **Reviewed** — Muse has reviewed the diff and relevant context. No actionable comments remain.
- [ ] **Report** — Print pass/fail for each item, the PR URL on its own line, and the verdict: "Ready to merge" or "Load the `finish` skill again after addressing failures."
