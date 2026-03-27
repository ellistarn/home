---
name: declarative-designs
description: Framework for design-driven development. Load when authoring designs, implementing from them, deciding what to preserve during changes, or reconciling implementations.
---

# Declarative Designs

A design encodes intent — what the system is, why it exists, the constraints it operates under, and
the qualities that matter. Intent is durable in a way that implementation is not. Languages change,
architectures get replaced, patterns fall out of favor, but the problem being solved and the
properties that matter survive those transitions. A design captures what must hold; an implementation
is one way of making it hold.

This makes designs the source artifact. Implementations are compiled from them. Any implementation
that satisfies the design is valid, and where a design is silent on mechanism, implementation choices
are unconstrained — free to change as better approaches emerge. The boundary between what a design
commits to and what it leaves open is the most important thing a design communicates, because
everything on one side is protected and everything on the other side is free.

## Reconciliation

If designs are source and implementations are derived, then the steady state is continuous
reconciliation — closing the gap between what the design declares and what the implementation does.
This is not a phase that ends. Agents are imperfect, implementations start rough, and each pass is an
opportunity to bring the implementation closer to the design's intent. Better test coverage. Tighter
error handling. More accurate documentation. None of these change what the system is — they improve
how well the current implementation satisfies it.

Test coverage validates design commitments, not implementation details, because tests rooted in
implementation break when the implementation changes — even when the design is still satisfied. Tests
rooted in design commitments are stable across refactors, and they answer the question that matters:
does this implementation actually do what the design says it should?

Documentation reflects the current design, not a historical version of it. When documentation drifts
from the design, it becomes a source of confusion about what the system actually is. That drift is a
gap like any other, and it closes the same way.

When a design changes, the implementation converges toward the new state. Implementation choices that
still satisfy the updated design survive; those that don't get replaced. This is convergence, not
rebuild — most of any implementation is unaffected by most design changes, and preserving what still
works is part of what makes reconciliation efficient.

## Design evolution

Designs are not written once. They grow through use. Someone builds from the design, uses what they
built, and discovers that the design was silent on something that turns out to matter — a failure mode
nobody anticipated, a quality attribute that only becomes visible under real conditions, a constraint
that was implicit in the team's understanding but never captured. These gaps are the normal output of
building real systems.

When implementation reveals that a design was wrong, the design is updated explicitly. The
implementation does not silently become the new design. When usage reveals a gap, that gap becomes a
design revision, not an implementation workaround. The difference matters: a workaround encodes the
discovery in a place where it can't be reasoned about, can't be tested against, and will be lost the
next time the implementation is re-derived. A design revision makes the discovery permanent.

## What makes a design work

Everything above depends on the design being good enough to compile from. A design that fails at its
job degrades every other part of the system — reconciliation has no target, tests have no anchor, and
implementation choices have no boundary.

A design declares intent, constraints, and quality attributes — not mechanism. When a design
prescribes implementation, it captures the wrong thing. The question is always what underlying intent
the mechanism was trying to serve, and that intent is what belongs in the design. A design that says
"use a message queue" when it means "producers and consumers are decoupled and independently
scalable" has locked the implementation without gaining anything — the intent is more durable, more
portable, and more useful to whoever is compiling from it.

A design must be specific enough that an implementation can fail to satisfy it. A design that says
"the system is performant" cannot be violated, which means it cannot be reconciled toward. It
provides no signal about whether the current implementation is adequate or falling short. Specificity
is what gives a design teeth — the ability to distinguish an implementation that satisfies it from
one that doesn't.

Ambiguity about what is a design commitment and what is an implementation choice is a defect in the
design. Every other part of this system depends on that boundary being clear — without it, there is
no way to know what to protect during changes, what to test for, or what latitude exists for
improvement. A design that is unclear about its own boundaries cannot function as source.
