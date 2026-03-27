---
name: declarative-designs
description: Framework for design-driven development. Load when authoring designs, implementing from them, deciding what to preserve during changes, or reconciling implementations.
---

# Declarative Designs

Agents are powerful but unfocused. Without shared context, every session starts from zero — inferring
intent from code, guessing at priorities, spending time on things that don't matter. A design
eliminates that search. It encodes what the system is, what matters, and where the boundaries are, so
that agents spend their time building and improving rather than figuring out what to build.

This is the core value of a design: it makes agents fast by making them focused. Everything else
follows from this.

## Designs are source

A design captures intent — the problem being solved, the constraints, the quality attributes that
matter. Intent is durable in a way that implementation is not. Languages change, architectures get
replaced, patterns fall out of favor, but the problem and its properties survive those transitions.

Implementations are compiled from designs. Any implementation that satisfies the design is valid, and
where a design is silent on mechanism, implementation choices are unconstrained. This is where agents
add value — they have full latitude over the how, while the what stays fixed.

The boundary between what a design commits to and what it leaves open is the most important thing a
design communicates:

- Everything on one side is protected — it must hold across any implementation
- Everything on the other side is free — it can change as better approaches emerge

Getting this boundary right is what makes a design useful. Too much commitment and the agent has no
room to work. Too little and the agent has no direction.

## Reconciliation is the steady state

If designs are source and implementations are derived, then the normal mode of work is continuous
reconciliation — closing the gap between what the design declares and what the implementation does.
This is not a phase that ends. Agents are imperfect, implementations start rough, and each pass
brings the implementation closer to the design's intent:

- Better test coverage
- Tighter error handling
- More accurate documentation
- Cleaner structure

None of these change what the system is. They improve how well the current implementation satisfies
it. This is why designs make speed safe — you can ship fast because you have a defined target to
converge toward. Velocity without a design is drift. Velocity with a design is iteration.

Test coverage validates design commitments, not implementation details. Tests rooted in
implementation break when the implementation changes — even when the design is still satisfied. Tests
rooted in design commitments are stable across refactors, and they answer the question that actually
matters: does this implementation do what the design says it should?

When a design changes, the implementation converges toward the new state. Choices that still satisfy
the updated design survive; those that don't get replaced. This is convergence, not rebuild — most of
any implementation is unaffected by most design changes.

## Designs grow through use

Designs are not written once. The cycle is: design, build, use, discover, revise.

Building from a design reveals gaps — failure modes nobody anticipated, quality attributes that only
become visible under real conditions, constraints that were implicit but never captured. These
discoveries are the normal output of building real systems, and they are valuable. The question is
where they go.

- When implementation reveals a design was wrong, the design is updated explicitly. The
  implementation does not silently become the new design.
- When usage reveals a gap, that gap becomes a design revision, not an implementation workaround. A
  workaround encodes the discovery in a place where it can't be reasoned about, can't be tested
  against, and will be lost the next time the implementation is re-derived. A revision makes the
  discovery permanent.

Designs improve in accuracy and specificity over time, not in length. A design that grows without
bound is accumulating implementation details, not refining intent.

## What makes a design work

Everything above depends on the design being good enough to compile from. A design that fails at this
job makes agents slower, not faster — reconciliation has no target, tests have no anchor, and
implementation choices have no boundary.

**Intent, not mechanism.** A design declares what and why, not how. A design that says "use a message
queue" when it means "producers and consumers are decoupled and independently scalable" has locked
the implementation without gaining anything. The intent is more durable, more portable, and more
useful to compile from.

**Specific enough to violate.** A design that says "the system is performant" cannot be reconciled
toward — it provides no signal about whether the current implementation is adequate or falling short.
Specificity gives a design teeth: the ability to distinguish an implementation that satisfies it from
one that doesn't.

**Clear about its own boundaries.** Ambiguity about what is a design commitment and what is an
implementation choice is a defect. Every other part of this system depends on that boundary — what to
protect during changes, what to test for, what latitude exists for improvement. A design unclear about
its own boundaries cannot function as source.
