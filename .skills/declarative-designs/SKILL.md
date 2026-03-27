---
name: declarative-designs
description: How to author, implement from, and reconcile toward declarative designs — desired state declarations that implementations converge toward continuously.
---

# Declarative Designs

A declarative design is a desired state declaration for a system — what it is, what properties it
has, what constraints it operates under. It does not say how. This is how any control system works: a
stable reference, a feedback loop, and a process that closes the error. The design is the reference.
The implementation converges toward it. The design is the control plane. The code is the data plane.

This is not spec-and-implement. A spec is consumed once and goes stale. A design persists across
every pass — across sessions, refactors, rewrites — and the implementation gets better against it
each time. Speed comes from this: declare objectives and constraints, and the rest is filled in. The
design cost is paid once. Everything after that is convergence.

## Writing designs

A design captures intent — the problem being solved, the constraints, the quality attributes that
matter. A design that says "producers and consumers are decoupled and independently scalable" gives
room to choose message queues today and shared-memory channels tomorrow. A design that says "use
RabbitMQ" has locked the implementation without gaining anything. Intent survives technology
transitions. Mechanism does not.

What a design leaves out is as important as what it includes. A Kubernetes Deployment says "three
replicas of this image" — not which nodes, not how to handle failures, not how to sequence a rollout.
That silence is not underspecification. It is the design. The controller fills it, and fills it
differently as conditions change. This is what distinguishes a design from a spec: a spec tries to be
complete. A design is powerful because it is sparse. Sparseness is where agents add value — and where
implementations improve over time without the design changing.

But sparseness is not vagueness. A design must be specific enough that an implementation can fail to
satisfy it. "The system is performant" cannot be reconciled toward — it provides no signal. "P99
latency under 100ms at 1000 concurrent connections" can. Specificity is what makes the feedback loop
functional.

A design operates at the altitude where changing a commitment changes the product. If something can
change without the product changing, it belongs in the implementation. If it cannot, it belongs in the
design. This is the boundary between commitment and freedom, and it is the most important thing a
design communicates. Ambiguity about this boundary is a defect. A design that starts at the right
altitude and gradually descends into interface details, flag names, or behavioral specifications has
lost the boundary. Hold the altitude.

The craft of a design matters because a design occupies a context window and competes for attention.
A thesis that builds understanding — where each idea follows from the previous and a reader can
extend the reasoning to situations the design did not enumerate — is more durable than a list of
assertions. Every sentence that does not carry weight degrades the ones that do. Designs grow in
specificity over time, not in length.

## Implementing from designs

An implementation satisfies a design by meeting its objectives, constraints, and quality attributes.
Where the design is silent, implementation choices are free and should improve over time.

Tests validate design commitments, not implementation details. Tests rooted in implementation break
when the implementation changes, even when the design is still satisfied. Tests rooted in design
commitments survive refactors and answer the only question that matters: does this implementation do
what the design says it should?

Building and using the implementation reveals what the design missed — failure modes nobody
anticipated, quality attributes that only surface under real conditions, constraints that were
implicit but never captured. When this happens, the gap becomes a design revision, not an
implementation workaround. The implementation does not silently become the new design. A workaround
encodes the discovery where it cannot be reasoned about or tested against, and will be lost the next
time the implementation is re-derived. A revision makes the discovery permanent.

## Reconciliation

Reconciliation is the control loop — continuous improvement without changing what the system is. The
design holds still. The implementation gets better. Velocity without a design is drift. Velocity with
a design is iteration.

When a design changes, the implementation converges toward the new state. Choices that still satisfy
the updated design survive. Those that do not get replaced. Convergence, not rebuild.

Beyond convergence, each reconciliation pass can improve the implementation along any dimension the
design cares about. Correctness is the foundation — does the implementation satisfy the design, are
commitments tested, are edge cases and failure modes covered? Simplicity is the steady-state force —
the design is the fixed point, and anything that can be removed or simplified without violating a
commitment should be. These extend to whatever the design declares: performance characteristics,
documentation accuracy, error quality, API ergonomics. The design determines what gets reconciled.
The reconciliation loop closes the gap.
