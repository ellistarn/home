---
name: declarative-designs
description: How to author, implement from, and reconcile toward declarative designs — desired state declarations that implementations converge toward continuously.
---

# Declarative Designs

A declarative design transfers a human's judgment into a persistent artifact that agents reconcile
toward. It declares what a system is, what properties it has, and what constraints it operates
under — not how. The design makes the human's judgment persistent and the agent's work cumulative.
Without it, every session starts from zero, work doesn't accumulate, and quality depends on the human
reviewing everything — which doesn't scale at agent speed.

A design is sparse because the human's time is the scarce resource. It captures intent because intent
persists across implementation changes. It is evaluable because the human can't review every line — if
the design is satisfied, the implementation is acceptable even if the human hasn't read it. The
design is the control plane. The code is the data plane. This is how any control system works: a
stable reference, a feedback loop, and a process that closes the error.

This is not spec-and-implement. A spec is consumed once and goes stale. A design persists across
sessions, refactors, and rewrites, and the implementation gets better against it each time. As an
artifact, a design is text that occupies a context window, competes for attention, and steers work.
Every constraint that follows — compression, specificity, sparseness — is a consequence of this form.
A thesis that builds understanding is more durable than a list of assertions. Every sentence that
does not carry weight degrades the ones that do. Designs grow in specificity over time, not in
length.

## Writing designs

### Intent

A design captures what and why. Consider a messaging system: "Producers and consumers are decoupled.
Messages are delivered at least once. Ordering is preserved within a partition key. Consumers are
independently scalable." This says what the system promises without prescribing how. The
implementation can use Kafka today and in-process channels tomorrow. The design survives both.

The failure mode is overspecification. "Use Kafka with three partitions, JSON serialization, and
consumer groups for fan-out." The design has prescribed the implementation. Swap to in-process
channels for testing? Redesign. The design spent its budget on the part that changes and left nothing
for the part that persists.

_Test: can the implementation change without the design changing? If not, the design has captured
mechanism._

### Sparseness

What a design leaves out is as important as what it includes. A Kubernetes Deployment says "three
replicas of this image" — not which nodes, not how to handle failures, not how to sequence a rollout.
The controller fills that silence, and fills it differently as conditions change. This is what
distinguishes a design from a spec: a spec tries to be complete. A design is powerful because it is
sparse. Sparseness is where implementations improve over time without the design changing.

A design operates at the altitude where changing a commitment changes the product. If something can
change without the product changing, it belongs in the implementation. If it cannot, it belongs in the
design. This boundary between commitment and freedom is the most important thing a design
communicates. A design that starts at the right altitude and gradually descends into interface
details, flag names, or behavioral specifications has lost the boundary. Hold the altitude.

### Specificity

Sparseness is not vagueness. A design must be specific enough that an implementation can fail to
satisfy it. The messaging system's "at least once" is specific — an implementation that drops messages
under backpressure has failed. "P99 latency under 100ms at 1000 concurrent connections" can be
reconciled toward. Specificity is what makes the feedback loop functional.

The failure mode is vagueness. "The system handles messages reliably." Every implementation trivially
satisfies this, which means it provides no signal for reconciliation. A commitment that cannot be
violated cannot be converged toward.

_Test: can an implementation fail to satisfy this? If nothing fails it, it is not a design
commitment._

### Boundaries

Every design commitment must be unambiguous about whether it is a commitment. The messaging design
above draws this boundary: at-least-once delivery is committed, exactly-once is not. A reader knows
which is which.

The failure mode is ambiguity. "Messages are delivered to consumers." Is ordering a commitment? Is
exactly-once? The implementation will decide silently, and those silent decisions become implicit
commitments — impossible to reason about, impossible to test against, discovered only when someone
makes a different choice and something breaks.

_Test: can two people read this and make different choices about the same concern? If so, the boundary
between commitment and freedom is missing._

## Reconciliation

Reconciliation is the control loop — continuous improvement without changing what the system is. The
design holds still. The implementation gets better. Velocity without a design is drift. Velocity with
a design is iteration.

### Closing gaps

An implementation satisfies a design by meeting its objectives, constraints, and quality attributes.
Where the design is silent, implementation choices are free and should improve over time. Tests
validate design commitments, not implementation details — tests rooted in implementation break when
the implementation changes, even when the design is still satisfied. Tests rooted in commitments
survive refactors and answer the only question that matters: does this implementation do what the
design says it should?

Each pass can improve the implementation along any dimension the design cares about. Correctness is
the foundation — are commitments tested, edge cases covered, failure modes handled? Simplicity is the
steady-state force — anything that can be removed or simplified without violating a commitment should
be. These extend to whatever the design declares: performance characteristics, documentation
accuracy, error quality, API ergonomics. The design determines what gets reconciled.

### Discovering gaps

Building and using the implementation reveals what the design missed — failure modes nobody
anticipated, quality attributes that only surface under real conditions, constraints that were
implicit but never captured. When this happens, the gap becomes a design revision, not an
implementation workaround. The implementation does not silently become the new design. A workaround
encodes the discovery where it cannot be reasoned about or tested against, and will be lost the next
time the implementation is re-derived. A revision makes the discovery permanent.

A design that does not incorporate its discoveries goes stale — and a stale design is worse than a
gap. A gap is silent. A stale design actively steers toward a state the system has already abandoned.

_Test: does the design reflect current understanding, or a past assumption that survived because
nobody updated the document?_

### Converging

When a design changes, the implementation converges toward the new state. Choices that still satisfy
the updated design survive. Those that do not get replaced. Convergence, not rebuild.
