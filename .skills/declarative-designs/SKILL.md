---
name: declarative-designs
description: Objectives for design-driven development. Load when authoring designs, implementing from them, deciding what to preserve during changes, or reconciling implementations.
---

# Declarative Designs

Designs are source. Implementations are compiled from them. The gap between current implementation and declared design closes continuously.

## At Rest

- Implementations satisfy all objectives, constraints, and quality attributes declared in the design
- Where a design is silent, implementation choices are unconstrained and improve over time
- Test coverage validates design commitments, not implementation details
- Documentation accurately reflects the current design
- Gaps between design and implementation do not persist

## On Change

- When a design changes, the implementation converges — preserving what still satisfies it, replacing what doesn't
- When implementation reveals a design is wrong, the design is updated explicitly before the implementation diverges
- Gaps discovered through usage are captured as design revisions, not implementation workarounds

## On Designs Themselves

- Designs declare intent, constraints, and quality attributes — not mechanism
- A design is specific enough that an implementation can fail to satisfy it
- Ambiguity about what is a design commitment vs. an implementation choice is a defect in the design
- Implementation details in a design are revised to capture the underlying intent
