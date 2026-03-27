---
name: declarative-designs
description: How to author, implement from, and reconcile toward declarative designs — desired state declarations that implementations converge toward continuously.
---

# Declarative Designs

A declarative design is a desired state declaration for a system — what it is, what properties it
has, what constraints it operates under. It does not say how. This is not spec-and-implement. It is
declare-and-converge. The design is the control plane. The code is the data plane. The design
persists. The implementation converges toward it.

The cycle is: design, implement, use, discover, revise. Speed comes from sparseness — declare
objectives and constraints, the rest is filled in. Because the design persists across passes, that
cost is paid once. A detailed spec goes stale. A sparse design compounds.

## Writing designs

A design captures intent — the problem being solved, the constraints, the quality attributes that
matter. It does not capture mechanism. A design that says "producers and consumers are decoupled and
independently scalable" gives room to choose message queues today and shared-memory channels tomorrow.
A design that says "use RabbitMQ" has locked the implementation without gaining anything. Intent
survives technology transitions. Mechanism does not.

What a design leaves out matters as much as what it includes. A Kubernetes Deployment says "three
replicas of this image." It does not say which nodes, how to handle failures, or how to sequence a
rollout. The controller fills that silence, and fills it differently as conditions change. Deliberate
sparseness is what gives the implementation room to improve over time — it is the space where agents
add value.

A design must be specific enough that an implementation can fail to satisfy it. "The system is
performant" cannot be reconciled toward. It provides no signal about whether the current state is
adequate or falling short. Specificity is what makes the feedback loop functional — the ability to
distinguish an implementation that satisfies the design from one that does not.

A design must be clear about its own boundaries — what is a commitment and what is left to the
implementation. Ambiguity here is a defect. Every other part of this system depends on that
distinction: what to protect during changes, what to test for, what latitude exists for improvement.

A design builds understanding that transfers to situations it did not enumerate. A thesis that
produces its conclusions is more durable than a list of assertions, because the thesis adapts to new
contexts while the list can only be consulted. The reasoning should be visible enough that a reader
can extend it.

A design occupies a context window and competes for attention. Every sentence that does not carry
weight degrades the ones that do. Designs improve in accuracy and specificity over time, not in
length.

## Implementing from designs

The design is the source of truth. An implementation satisfies it by meeting its objectives,
constraints, and quality attributes. Where the design is silent, implementation choices are free —
and should improve over time.

Tests validate design commitments, not implementation details. Tests rooted in implementation break
when the implementation changes, even when the design is still satisfied. Tests rooted in design
commitments survive refactors and answer the question that matters: does this implementation do what
the design says it should?

When implementation or usage reveals a gap in the design — a failure mode nobody anticipated, a
quality attribute that only surfaces under real conditions, a constraint that was implicit but never
captured — that gap becomes a design revision, not an implementation workaround. The implementation
does not silently become the new design. A workaround encodes the discovery where it cannot be
reasoned about or tested against, and will be lost the next time the implementation is re-derived. A
revision makes the discovery permanent.

## Reconciliation

Reconciliation is continuous improvement of the implementation without changing what the system is.
The design holds still. The implementation gets better. This is what makes speed safe — ship fast,
because there is a defined target to converge toward. Velocity without a design is drift. Velocity
with a design is iteration.

When a design changes, the implementation converges toward the new state. Choices that still satisfy
the updated design survive. Those that do not get replaced. Convergence, not rebuild.

Beyond convergence, reconciliation is an opportunity to improve the implementation along dimensions
the design cares about but did not fully achieve on the first pass:

**Correctness.** Does the implementation satisfy the design? Are design commitments tested? Are edge
cases from constraints covered? Are failure modes handled? Correctness is the foundation —
everything else assumes the implementation does what the design says it should.

**Simplicity.** Can the implementation be simpler while still satisfying the design? Accidental
complexity accumulates. Patterns that made sense during initial implementation may not survive a
second look. The design provides the fixed point — anything that can be removed or simplified without
violating a design commitment should be.

**Performance.** Do quality attributes hold under real conditions? Can hot paths improve? Performance
work without a design tends to optimize the wrong things. The design identifies what matters.

**Documentation.** Does documentation reflect the current design accurately? Documentation that
drifts from the design is a source of confusion about what the system is. That drift is a gap like
any other.
