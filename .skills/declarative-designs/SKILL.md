---
name: declarative-designs
description: How to author, implement from, and reconcile toward declarative designs — desired state declarations that implementations converge toward continuously.
---

# Declarative Designs

A declarative design is a persistent declaration of what a system should be — properties,
constraints, promises. Humans change designs. Agents reconcile the codebase toward them.

## Problem

Without a design, the human is the quality function. Every agent session starts from zero. The human
reviews every line of code to verify intent, and that doesn't scale — the agent can produce code
faster than the human can verify it. Quality becomes a function of vigilance.

A design makes the human's judgment persistent. The agent reads the design and builds toward it.
Tests — automated or manual — verify that the implementation satisfies the design. If the tests pass,
the implementation is acceptable without the human reading the code. The design is the human's
control surface over the codebase — they express what they want by changing it, and the agent
converges the implementation toward whatever it says.

## How it works

A design divides every concern into one of three zones:

- **What the design says** — obligations. The agent must satisfy these.
- **What the design doesn't say, within scope** — the agent's judgment. Make good choices, but hold
  them lightly. These can change between passes without the product changing.
- **What the design scopes out** — the agent doesn't touch these.

The human primarily cares about system interface — how the system looks to its users, to other
systems, to operators. Designs focus there. The line between obligation and judgment is wherever the
human draws it: sometimes high ("messages are delivered at least once"), sometimes lower ("use
Kubernetes watch for change detection"). Respect wherever the line is drawn.

### Authoring

The human is the authority on designs. The agent may help draft, but a design captures the human's
intent, not the agent's preferences.

A design should establish context before introducing the shape — the reader should understand the
problem before encountering the solution. Within each section, show the interface first and explain
it after. Describe how the system works rather than arguing for why it's good.

Scope the design explicitly. There are two kinds of omission and they mean different things:

- **Delegation** — the agent fills it. A design that says "at least once
  delivery" but is silent about retry strategy is delegating that choice — the agent decides.
- **Not covered** means a concern is outside the design's domain entirely. List these so a reader
  knows the omission is a boundary, not a gap.

Apply these checks to every commitment:

- **Falsifiable?** "At least once delivery" — an implementation that drops messages has failed it.
  "Handles messages reliably" — every implementation trivially satisfies it. A commitment that
  nothing can violate carries no information.
- **Boundary clear?** "Messages are delivered to consumers" — is ordering committed? Is exactly-once?
  If the design doesn't say, the agent decides, and those silent decisions become implicit
  commitments that surface only when someone makes a different choice and something breaks. Where
  freedom is intended, make it explicit.

### Implementing

Read the whole design first. Identify all the commitments, then build something that satisfies them
simultaneously. Don't treat the design as a task list and go line by line.

Where the design commits, satisfy the commitment. Where the design is silent, make a good judgment
call — but hold it lightly. Silence means this choice is yours and can change later. When
commitments tension with each other, surface that to the human rather than silently prioritizing one.

When the design feels wrong or incomplete — a failure mode it didn't anticipate, a constraint that
only surfaces under real conditions — surface it to the human. Don't silently deviate. A discovery
encoded as a workaround is lost the next time the implementation is re-derived. A discovery that
becomes a design revision is permanent.

### Reconciling

Current state, desired state, diff, action. Every time you work in code that has a design, this is
the posture.

Test design commitments, not implementation choices. A test rooted in a commitment survives refactors.
A test rooted in implementation breaks when the implementation changes even though the design is
still satisfied.

When you find a gap, classify it:

- **Implementation is wrong** — the code doesn't satisfy a commitment. Fix the code.
- **Design is stale** — the system has moved past what the design says. Surface this to the human —
  design revisions are their call.

A stale design is worse than a missing one — it steers toward a state the system has already moved
past. When a design is revised, choices that still satisfy it survive. Those that don't get replaced.
Convergence, not rebuild.
