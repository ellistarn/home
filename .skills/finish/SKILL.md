---
name: finish
description: Completion checklist — rebase, squash, tests, design reconciliation, muse review. Load before declaring any task complete.
---

# Finish

Before work is declared complete, verify every item. Items that can be verified
programmatically, verify. Items that require human confirmation, ask.

## Checklist

[] **Rebased** — PR branch is rebased to the latest commit on the target remote branch.
[] **Tested** — Tests exist that verify feature correctness and prevent regression. Not just "tests pass" — tests were written or updated for this change.
[] **Validated** — Change has been manually validated in a development environment. If this hasn't happened, ask the human to confirm.
[] **Committed** — Single commit with a message that matches the PR title and body. Show not tell for perf improvements, logging changes, or anything else.
[] **Designs satisfied** — Declarative designs in `designs/` are not violated by the implementation.
[] **Designs ambiguity surfaced** — Design gaps and proposed updates have been reviewed by the human
[] **Muse approved** — Consult muse `muse ask --new ...` with the diff and relevant context. If the muse has actionable comments, address them and re-consult `muse ask ...` with the updated diff and relevant context. Repeat until no actionable comments remain.

## Report

Print pass/fail for each item, the PR URL, and details for any failures.
If unresolved: "Load the `finish` skill again after addressing failures."
If clean: "Ready to merge."
