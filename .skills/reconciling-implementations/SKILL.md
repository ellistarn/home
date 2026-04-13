---
name: reconciling-implementations
description: Properties of a well-formed implementation against a design. Load when implementing or verifying code against a design.
---

# Reconciling Implementations

- [ ] All commitments are satisfied simultaneously — not treated as a sequential task list.
- [ ] Implementation choices not mandated by the design are identified as discretionary, not
  hardcoded as requirements.
- [ ] When commitments conflict, the tension is surfaced to the human — not one silently prioritized.
- [ ] Gaps are classified and surfaced. Implementation is wrong (fix the code) or design is stale
  (surface to the human). No workarounds for design limitations.
- [ ] Tests verify commitments, not implementation. A test rooted in a commitment survives refactors.
