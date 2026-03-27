---
name: declarative-designs
description: How to author, implement from, and reconcile toward declarative designs — desired state declarations that implementations converge toward continuously.
---

# Declarative Designs

A declarative design is a desired state declaration for a system — what it is, what properties it
has, what constraints it operates under. It does not say how. This is not spec-and-implement. It is
declare-and-converge. The design is the control plane. The code is the data plane. The design
persists. The implementation converges toward it.

## Silence is the design

A design declares what matters and is deliberately silent on everything else. That silence is not
underspecification — it is the design. A Kubernetes Deployment says "three replicas of this image." It
does not say which nodes, how to handle failures, or how to sequence a rollout. The controller fills
that silence, and fills it differently as conditions change. The sparseness is what makes the system
powerful.

A design that says "producers and consumers are decoupled and independently scalable" gives room to
choose message queues today and shared-memory channels tomorrow. A design that says "use RabbitMQ" has
locked the implementation without gaining anything. Intent survives technology transitions. Mechanism
does not.

Speed comes from this sparseness. Declare objectives and constraints. The rest is filled in — and
because the design persists across reconciliation passes, that cost is paid once. A detailed spec is a
one-time expenditure that goes stale. A sparse design compounds.

## Reconciliation

The steady state is continuous reconciliation — evaluating the current implementation against the
design and closing gaps. Better test coverage, tighter error handling, more accurate documentation,
cleaner structure. None of these change what the system is. They improve how well the implementation
satisfies it. This is what makes speed safe. Velocity without a design is drift. Velocity with a
design is iteration.

When a design changes, the implementation converges toward the new state. Choices that still satisfy
the updated design survive. Those that do not get replaced. Convergence, not rebuild.

Tests validate design commitments, not implementation details. Tests rooted in implementation break
when the implementation changes, even when the design is still satisfied. Tests rooted in design
commitments survive refactors and answer the question that matters: does this implementation do what
the design says it should?

## Designs grow through use

Designs are not written once. Building and using a system reveals what the design was silent on that
it should not have been — failure modes nobody anticipated, quality attributes that only surface under
real conditions, constraints that were implicit but never captured.

When implementation reveals a design was wrong, the design is updated explicitly. The implementation
does not silently become the new design. When usage reveals a gap, that gap becomes a design revision,
not an implementation workaround. A workaround encodes the discovery where it cannot be reasoned
about or tested against, and will be lost the next time the implementation is re-derived. A revision
makes the discovery permanent.

## What makes a design work

A design occupies a context window. It competes for attention with the implementation, the tests, the
conversation. Every sentence that does not carry weight degrades the ones that do. This is not a style
concern — it is functional. A wordy design wastes the same resource that makes reconciliation
possible.

**Intent, not mechanism.** A design captures what and why. Mechanism belongs to the implementation.
A design that prescribes how has spent its budget on the part that changes and left nothing for the
part that persists.

**Specific enough to violate.** A design that cannot be failed cannot be reconciled toward. "The
system is performant" provides no signal about whether the current state is adequate. Specificity is
what makes the feedback loop functional.

**Clear boundaries.** What is a commitment and what is left to the implementation. Ambiguity here is
a defect — without this boundary, there is no way to know what to protect and what to improve.

**Generative.** A design builds understanding that transfers to situations it did not enumerate. A
thesis that produces its conclusions is more durable than a list of assertions, because the thesis
adapts to new contexts while the list can only be consulted. The reasoning should be visible enough
that a reader can extend it.

**Every word earns its place.** Designs improve in accuracy and specificity over time, not in length.
A sentence that restates a previous one, a flourish that does not inform, a word that could be cut —
each one costs attention that should have gone to signal. Compression is not brevity for its own
sake. It is respect for the constraint that makes designs work: finite attention, applied to what
matters.
