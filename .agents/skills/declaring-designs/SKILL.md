---
name: declaring-designs
description: Properties of a well-formed design. Load when creating or iterating on a design.
---

# Declaring Designs

A design is a story of how the system works. Humans change designs. Agents reconcile
implementations toward them. The design is the human's control surface.

A design divides every concern into one of three zones:

- **What the design says** — obligations. The implementation must satisfy these.
- **What the design doesn't say, within scope** — the implementer's judgment. These choices can
  change between passes without the product changing.
- **What the design scopes out** — not touched.

- [ ] The design stands alone. It does not describe changes from previous state or reference the
  current implementation.
- [ ] The design is consistent. No statements contradict each other or other designs.
- [ ] Every abstraction earns its existence. Nothing can be deleted or collapsed without losing
  capability.
- [ ] Boundaries are explicit and falsifiable. Every concern the reader would expect is committed to,
  delegated, or scoped out. Each commitment can be concretely violated.
- [ ] Every element — examples, diagrams, sections — contributes to a cohesive story.
- [ ] Names improve intuitive understanding of the system. A reader encountering a name should
  correctly guess its purpose.
- [ ] Concepts are introduced before they are referenced.
- [ ] Concrete artifacts — interfaces, examples, schemas — carry the design. Prose orients the reader
  between them.
- [ ] Factual claims are verified.
- [ ] Rejected alternatives appear at the end.
- [ ] Every word has weight. No dramatic language, no filler.
