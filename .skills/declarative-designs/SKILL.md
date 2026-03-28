---
name: declarative-designs
description: How to author, implement from, and reconcile toward declarative designs — desired state declarations that implementations converge toward continuously.
---

# Declarative Designs

Declare what a system is, what properties it has, and what constraints it operates under — not how.
Implementations converge toward the design continuously. The design is the control plane. The code is
the data plane. Speed comes from declaring only what matters and leaving the rest as freedom.

## The model

A declarative design is a desired state declaration. It persists across sessions, refactors, and
rewrites, and the implementation gets better against it each time. This is how any control system
works: a stable reference, a feedback loop, and a process that closes the error.

This is not spec-and-implement. A spec is consumed once and goes stale. A design persists because it
captures intent rather than mechanism — and intent survives the technology transitions that make specs
obsolete. The design cost is paid once. Everything after that is convergence.

As an artifact, a design is text that occupies a context window, competes for attention, and steers
work. Every constraint that follows — compression, specificity, sparseness — is a consequence of this
form.

## What makes a design work

### Intent

A design captures what and why. Consider a messaging system: "Producers and consumers are decoupled.
Messages are delivered at least once. Ordering is preserved within a partition key. Consumers are
independently scalable." This says what the system promises without prescribing how. The
implementation can use Kafka today and in-process channels tomorrow. The design survives both.

### Sparseness

What a design leaves out is as important as what it includes. A Kubernetes Deployment says "three
replicas of this image" — not which nodes, not how to handle failures, not how to sequence a rollout.
The controller fills that silence, and fills it differently as conditions change. This is what
distinguishes a design from a spec: a spec tries to be complete. A design is powerful because it is
sparse. Sparseness is where implementations improve over time without the design changing.

A design occupies a context window. A thesis that builds understanding — where each idea follows from
the previous and a reader can extend the reasoning — is more durable than a list of assertions. Every
sentence that does not carry weight degrades the ones that do. Designs grow in specificity over time,
not in length.

### Specificity

Sparseness is not vagueness. A design must be specific enough that an implementation can fail to
satisfy it. "P99 latency under 100ms at 1000 concurrent connections" can be reconciled toward. "The
system is performant" cannot — it provides no signal. Specificity is what makes the feedback loop
functional.

The altitude test: if something can change without the product changing, it belongs in the
implementation. If it cannot, it belongs in the design. This boundary between commitment and freedom
is the most important thing a design communicates.

## What breaks a design

### Overspecified

"Use Kafka with three partitions, JSON serialization, and consumer groups for fan-out." The design
has prescribed the implementation. Swap to in-process channels for testing? Redesign. The design
spent its budget on the part that changes and left nothing for the part that persists.

_Test: can the implementation change without the design changing? If not, the design has captured
mechanism._

### Vague

"The system handles messages reliably." Every implementation trivially satisfies this, which means it
provides no signal for reconciliation. A commitment that cannot be violated cannot be converged
toward.

_Test: can an implementation fail to satisfy this? If nothing fails it, it is not a design
commitment._

### Ambiguous

"Messages are delivered to consumers." Is ordering a commitment? Is exactly-once? The implementation
will decide silently, and those silent decisions become implicit commitments — impossible to reason
about, impossible to test against, discovered only when someone makes a different choice and
something breaks.

_Test: can two people read this and make different choices about the same concern? If so, the boundary
between commitment and freedom is missing._

### Stale

The design says "consumers process messages independently." Six months ago, the team discovered two
consumers have an ordering dependency. The workaround is in the code. The design still says
independent. A stale design is worse than a gap — a gap is silent, but a stale design actively
steers toward a state the system has already abandoned.

_Test: does the design reflect current understanding, or a past assumption that survived because
nobody updated the document?_

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
implementation workaround. A workaround encodes the discovery where it cannot be reasoned about or
tested against, and will be lost the next time the implementation is re-derived. A revision makes the
discovery permanent.

## Reconciliation

Reconciliation is the control loop — continuous improvement without changing what the system is. The
design holds still. The implementation gets better. Velocity without a design is drift. Velocity with
a design is iteration.

When a design changes, the implementation converges toward the new state. Choices that still satisfy
the updated design survive. Those that do not get replaced. Convergence, not rebuild.

Each reconciliation pass can improve the implementation along any dimension the design cares about.
Correctness is the foundation — does the implementation satisfy the design, are commitments tested,
are edge cases and failure modes covered? Simplicity is the steady-state force — anything that can be
removed or simplified without violating a commitment should be. These extend to whatever the design
declares: performance characteristics, documentation accuracy, error quality, API ergonomics. The
design determines what gets reconciled.
