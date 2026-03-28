---
name: declarative-designs
description: How to author, implement from, and reconcile toward declarative designs — desired state declarations that implementations converge toward continuously.
---

# Declarative Designs

A declarative design makes a human's judgment persistent so that agents can accumulate work against
it. It declares what a system is, what properties it has, and what constraints it operates under —
not how to build it. Without a design, every session starts from zero, quality depends on the human
reviewing every line, and that does not scale at agent speed.

A design is sparse because the human's time is the scarce resource. It captures intent because intent
survives implementation changes. It is evaluable because a satisfied design means the implementation
is acceptable even unread. The design is the control plane. The code is the data plane. A stable
reference, a feedback loop, a process that closes the error.

This is not spec-and-implement. A spec is consumed once and goes stale. A design persists across
sessions, refactors, and rewrites — the implementation gets better against it each time. As an
artifact, a design is text that occupies a context window, competes for attention, and steers work.
Every sentence that does not carry weight degrades the ones that do.

## Writing designs

### Intent

A design captures what and why. Consider a messaging system: "Producers and consumers are decoupled.
Messages are delivered at least once. Ordering is preserved within a partition key. Consumers are
independently scalable." This says what the system promises without prescribing how. The
implementation can use Kafka today and in-process channels tomorrow. The design survives both.

The failure mode is overspecification — detail at the wrong level. "Use Kafka with three partitions,
JSON serialization, and consumer groups for fan-out" prescribes the implementation. Swap to
in-process channels for testing? Redesign. The budget was spent on the part that changes, leaving
nothing for the part that persists. Overspecification is not excessive detail: "P99 latency under
100ms at 1000 concurrent connections" is precise and survives any implementation. "Use connection
pooling with a max of 50 connections" is equally precise but dies with the first architecture change.
The difference is altitude — one commits to an outcome, the other to a mechanism.

_Test: can the implementation change without the design changing? If not, the design has captured
mechanism._

### Sparseness

What a design leaves out is as important as what it includes. A Kubernetes Deployment says "three
replicas of this image" — not which nodes, not how to handle failures, not how to sequence a rollout.
The controller fills that silence, and fills it differently as conditions change. A spec tries to be
complete. A design is powerful because it is incomplete. Sparseness is where implementations improve
over time without the design changing.

A design operates where changing a commitment changes the product. If something can change without the
product changing, it belongs in the implementation. If it cannot, it belongs in the design. This
boundary between commitment and freedom is the most important thing a design communicates. A design
that descends into interface details, flag names, or behavioral sequences has lost the boundary — it
has become a spec wearing a design's name.

Sparseness is not brevity. A design can be long if every sentence is a commitment. It can be short
and overspecified if those few sentences prescribe mechanism. The axis is commitment density, not word
count.

_Test: if the implementation filled this silence differently next month, would the product still be
what the design says it is? If not, the silence is a missing commitment. If so, the silence is
working._

### Specificity

Sparseness and vagueness look similar but work in opposite directions. A sparse design says less, but
what it says is sharp enough
that an implementation can fail to satisfy it. The messaging system's "at least once" is specific: an
implementation that drops messages under backpressure has failed. "The system handles messages
reliably" is vague: every implementation trivially satisfies it, so it provides no signal for
reconciliation.

The failure mode is unfalsifiable commitments. A commitment that nothing can violate cannot be
converged toward. It occupies space in the design without steering work — worse than absence, because
absence is silent while a vague commitment actively masquerades as a decision made. "The API is easy
to use" forecloses nothing. "Invalid inputs return structured errors with the failing field, the
constraint violated, and a valid example" can be tested, failed, and improved against.

_Test: can an implementation fail to satisfy this? If nothing can fail it, it is not a design
commitment — it is a wish._

### Boundaries

Specificity asks whether a commitment is precise enough to be violated. Boundaries asks a prior
question: is it clear which concerns are commitments and which are left to the implementation? The
messaging design above draws this boundary: at-least-once delivery is committed, exactly-once is not.
A reader knows which is which.

The failure mode is ambiguity — the silent cousin of vagueness. "Messages are delivered to
consumers." Is ordering a commitment? Is exactly-once? The implementation will decide, and those
silent decisions become implicit commitments: impossible to reason about, impossible to test against,
discovered only when someone makes a different choice and something breaks. Ambiguity does not leave
freedom; it delegates the decision to whoever moves first, then punishes whoever moves second.

_Test: can two people read this and make different choices about the same concern? If so, the
boundary between commitment and freedom is missing._

## Reconciliation

Reconciliation is the control loop: continuous improvement without changing what the system is. The
design holds still. The implementation closes the gap between current state and desired state.

### Closing gaps

An implementation satisfies a design by meeting its commitments. Where the design is silent,
implementation choices are free and should improve over time. The design determines what gets
reconciled — correctness, performance, error quality, whatever the design commits to. Dimensions the
design does not mention are implementation concerns, improved at the implementer's judgment.

Tests validate design commitments, not implementation details. A test rooted in implementation breaks
when the implementation changes, even when the design is still satisfied. A test rooted in a
commitment survives refactors and answers the only question that matters: does this implementation do
what the design says it should?

### Discovering gaps

Building and using the implementation reveals what the design missed — failure modes nobody
anticipated, quality attributes that only surface under real conditions, constraints that were
implicit but never captured. When this happens, the gap is a design revision, not an implementation
workaround. The implementation does not silently become the new design.

A workaround encodes the discovery where it cannot be reasoned about or tested against, and will be
lost the next time the implementation is re-derived. A revision makes the discovery permanent and
steerable. A design that does not incorporate its discoveries goes stale — and a stale design is
worse than a gap. A gap is silent. A stale design actively steers toward a state the system has
already abandoned.

When a design changes, the implementation converges toward the new state. Choices that still satisfy
the updated design survive. Those that do not get replaced. Convergence, not rebuild.

_Test: does the design reflect current understanding, or a past assumption that survived because
nobody updated the document?_
