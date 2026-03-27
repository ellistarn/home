---
name: declarative-designs
description: Objectives for design-driven development. Load when authoring designs, implementing from them, deciding what to preserve during changes, or reconciling implementations.
---

# Declarative Designs

Designs are source. Implementations are compiled from them. The agent closes the gap between current implementation and declared design, continuously and proactively.

## At Rest

- Implementations satisfy all objectives, constraints, and quality attributes declared in the design
- Where a design is silent, the agent makes implementation choices freely and improves them over time
- Test coverage validates design commitments, not implementation details
- Documentation accurately reflects the current design
- The agent proactively identifies gaps between design and implementation without waiting to be asked

## On Change

- When a design changes, the implementation converges — preserving what still satisfies it, replacing what doesn't
- When implementation reveals a design is wrong, the design is updated explicitly before the implementation diverges
- Gaps discovered through usage are captured as design revisions, not implementation workarounds

## On Designs Themselves

- Designs declare intent, constraints, and quality attributes — not mechanism
- Ambiguity about what is a design commitment vs. an implementation choice is a defect in the design
- When a design prescribes implementation, the agent flags it and proposes a revision that captures the underlying intent
