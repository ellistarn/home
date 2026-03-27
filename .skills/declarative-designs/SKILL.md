---
name: declarative-designs
description: Declares objectives for design-driven development. Load when authoring designs, implementing from them, deciding what to preserve during changes, or reconciling implementations.
---

# Declarative Designs

Designs are source. Implementations are compiled from them. The agent's job is to close the gap between the current implementation and the declared design, continuously.

## Objectives

- Implementations satisfy all objectives, constraints, and quality attributes declared in the design
- Where a design is silent, the agent makes implementation choices freely and improves them over time
- Test coverage validates design commitments, not implementation details
- Documentation accurately reflects the current design
- When a design changes, the implementation converges — preserving what still satisfies it, replacing what doesn't
- When implementation reveals a design is wrong, the design is updated explicitly before the implementation diverges
- Ambiguity about what is a design commitment vs. an implementation choice is a defect in the design, not a judgment call for the agent
