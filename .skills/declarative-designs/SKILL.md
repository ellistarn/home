---
name: declarative-designs
description: Principles for treating designs as the durable source of truth. Load when authoring designs, implementing from them, deciding what to preserve during changes, or reconciling implementations toward design objectives.
---

# Declarative Designs

Designs are the durable artifact. Implementations are derived. When there is tension between a design and its current implementation, the design is the source of truth and the implementation converges toward it.

## Principles

### Designs capture intent, not mechanism

A design specifies what the system is, why it exists, what constraints it operates under, and what qualities matter. It does not prescribe how those objectives are achieved unless the how is itself a design commitment. The boundary between "this is what we're building" and "this is how we happen to build it" must be explicit and maintained.

### Implementations are derived and replaceable

Any implementation that satisfies the design is valid. Where a design is silent on mechanism, the agent has latitude over architecture, algorithms, patterns, and structure. Implementation details can and should change as better approaches emerge.

### Reconciliation over perfection

Agents are imperfect. Implementations improve through continuous reconciliation against the design. Each pass can yield better test coverage, better performance, more accurate documentation, tighter error handling — without changing what the system is. Reconciliation is not a one-time event; it is the steady state.

### Designs change through deliberate revision, not implementation drift

When implementation reveals that a design was wrong, the design is updated explicitly. The implementation does not silently become the new design. Design changes are intentional and traceable.

### Implementations converge when designs change

When a design changes, the implementation converges toward the new state. The agent re-derives what is needed, preserving implementation choices that still satisfy the design and replacing those that don't.

### Designs are legible contracts

A design must make its boundaries clear — what is a commitment and what is left to the implementation. Ambiguity about whether something is a design decision or an implementation choice is itself a design defect. The agent cannot reconcile toward a target it cannot read.
