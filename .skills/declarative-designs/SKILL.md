---
name: declarative-designs
description: Framework for design-driven development. Load when authoring designs, implementing from them, deciding what to preserve during changes, or reconciling implementations.
---

# Declarative Designs

A declarative design is a desired state declaration for a system. It says what the system is, what
properties it has, and what constraints it operates under. It does not say how. An agent reads the
design, evaluates the current implementation against it, and closes gaps. This is not spec-and-
implement — it is declare-and-converge.

The design is the control plane. The code is the data plane. The design persists across sessions,
across refactors, across rewrites. The implementation is the variable that converges toward it. This
is how any control system works — a stable reference input, a feedback loop, and an actuator that
closes the error. The design is the reference. The agent is the controller. The implementation is the
plant.

## Silence is the design

A design declares what matters and is deliberately silent on everything else. That silence is not
underspecification — it is the design. In Kubernetes, a Deployment says "three replicas of this
image." It does not say which nodes, how to handle failures, or how to sequence a rollout. The
controller's intelligence fills that silence, and fills it differently as conditions change. The
sparseness is what makes the system powerful.

The same holds here. A design that says "producers and consumers are decoupled and independently
scalable" gives an agent room to choose message queues today and shared-memory channels tomorrow. A
design that says "use RabbitMQ" has locked the implementation without gaining anything. The intent
survives technology transitions. The mechanism does not.

This is also where speed comes from. You do not need to write a detailed specification. You need to
declare objectives and constraints. The agent fills in everything else — and because the design
persists across reconciliation passes, the cost is paid once. Every pass after that is convergence.
A detailed spec is a one-time expenditure that goes stale. A sparse design is a durable asset that
compounds.

## Reconciliation

The steady state is continuous reconciliation. The agent evaluates the current implementation against
the design and closes gaps — better test coverage, tighter error handling, more accurate
documentation, cleaner structure. None of these change what the system is. They improve how well the
implementation satisfies it.

This is what makes speed safe. Ship fast, because there is a defined target to converge toward.
Velocity without a design is drift. Velocity with a design is iteration.

When a design changes, the implementation converges toward the new state. Choices that still satisfy
the updated design survive. Those that do not get replaced. This is convergence, not rebuild.

Test coverage validates design commitments, not implementation details. Tests rooted in implementation
break when the implementation changes, even when the design is still satisfied. Tests rooted in
design commitments are stable across refactors, and they answer the question that matters: does this
implementation do what the design says it should?

## Designs grow through use

Designs are not written once. Building and using a system reveals what the design was silent on that
it should not have been — failure modes nobody anticipated, quality attributes that only surface under
real conditions, constraints that were implicit but never captured.

When implementation reveals a design was wrong, the design is updated explicitly. The implementation
does not silently become the new design. When usage reveals a gap, that gap becomes a design revision,
not an implementation workaround. A workaround encodes the discovery where it cannot be reasoned
about, cannot be tested against, and will be lost the next time the implementation is re-derived. A
revision makes the discovery permanent.

Designs improve in accuracy and specificity over time, not in length.

## What makes a design work

Everything above depends on the design being good enough to reconcile toward. Three properties make
that possible.

A design declares intent — not mechanism. It captures what and why. Mechanism belongs to the
implementation, where agents have latitude to improve it freely.

A design is specific enough that an implementation can fail to satisfy it. "The system is performant"
cannot be reconciled toward. It provides no signal about whether the current state is adequate or
falling short. Specificity is what makes the feedback loop functional.

A design is clear about its own boundaries — what is a commitment and what is left to the
implementation. Ambiguity here is a defect. The boundary between commitment and freedom is the most
important thing a design communicates, because everything on one side is protected and everything on
the other side is available for improvement.
