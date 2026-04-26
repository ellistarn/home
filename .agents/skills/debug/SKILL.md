---
name: debug
description: >
  Root-cause a known bug through evidence, not speculation.
  Load when a test is failing, flaking, or producing wrong results.
---

# Debugging

You cannot reason your way to a root cause. Code tells you what should happen.
Only execution tells you what does happen. Every claim about the bug must be
backed by evidence from a run, not from reading source.

Speed matters. Parallelize everything that can be parallelized — use subagents
to run independent work concurrently. Run only the failing test, never the full
suite.

## Workflow

### 1. Explore (parallel)

Launch these as concurrent subagents:

- **Characterize.** Loop the test with sanitizers and race detectors enabled.
  Record the failure rate. If you cannot trigger a failure, escalate stress.
  If you still cannot, stop — you cannot debug what you cannot trigger.
- **Understand.** Read the code paths exercised by the failing test. Identify
  the decision points, shared state, and concurrency boundaries. Form initial
  hypotheses — specific, falsifiable claims about what goes wrong. Write them
  down.
- **Instrument.** Read the output from the run that prompted this
  investigation. For the failing operation, the logs must answer: what
  triggered it, what path was taken at each decision point, and what the
  outcome was. If any answer is missing, the permanent instrumentation has a
  gap — surface it. Instrument liberally around the failure: decision points,
  handoffs, state changes, and dumps of the relevant state at each point.

### 2. Investigate (parallel, iterative)

For each hypothesis, launch a subagent:

1. **State the claim.** "X happens before Y because Z is not synchronized,"
   or "field F has value V after operation O because path P does not account
   for condition C."
2. **Design the experiment.** What instrumentation, assertion, or state dump
   would confirm or eliminate this claim? Add only that. Prefer assertions
   (they halt at the violation) over logging (you have to find the needle).
3. **Run only the failing test.** Loop it enough times to be confident (at
   least the count from the characterization).
4. **Read the evidence.** The output confirms, eliminates, or is inconclusive.
   Inconclusive means the experiment was badly designed — fix the experiment,
   don't move on.

### 3. Resolve

1. **Fix structurally.** Ask: why was this bug possible in the first place?
   A bad algorithm, missing abstraction, wrong data ownership, poor code
   organization, or a leaky API boundary — the root cause is the structural
   gap that allowed the bug to exist, not the specific instance. The fix must
   eliminate the category. If the fix doesn't change the answer to "why was
   this possible," you're patching a symptom.
2. **Verify.** Run the test the same number of times you used to characterize
   the failure. Zero failures at that count is the bar.
3. **Clean up.** Remove all diagnostic instrumentation. Every probe added
   during investigation is temporary unless it fills an instrumentation gap
   identified during exploration.
