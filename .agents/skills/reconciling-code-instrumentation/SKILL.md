---
name: reconciling-code-instrumentation
description: >
  Reconcile code instrumentation against the system's decision points.
  Load when adding or reviewing diagnostic logging.
---

# Instrumenting Code

You should be able to reconstruct what the system did and why from its logs
alone. Instrument decisions and handoffs, not computation.

## Workflow

1. **List decision points.** Read the code and identify decisions (path
   choices), handoffs (work crossing execution boundaries), state machines,
   and blocking operations. Create a TODO per decision point.

2. **Check visibility.** For each TODO: is the outcome already visible from
   existing logs? Cancel TODOs where it is.

3. **Gate each candidate.** For each surviving TODO, draft the log line, then
   run the per-line checklist below. If the checklist rejects it, cancel the
   TODO or rewrite it as a field addition on an existing line.

4. **Write the surviving lines.**

5. **Verify.** Exercise the instrumented code paths. The logs must answer:
   1. Why did this operation start?
   2. For each unit of work: was it acted on, skipped, or blocked? Why?
   3. What was the outcome and duration?

   If any question has no answer, the instrumentation is incomplete. If the
   answer appears in more than one log line, the instrumentation has
   redundancy.

## Per-line checklist

Run on every new or modified log line.

- [ ] **Level.** ERROR = something went wrong. INFO = acted on the outside
  world, once, after the effect. DEBUG = why the system did what it did.
- [ ] **Placement.** The line fires after the side effect it describes, not
  before. An exit log for an operation that didn't complete is a lie.
- [ ] **Context.** Set context at scope boundaries so every line within that
  scope inherits it. Handoffs break the call stack — a correlation identifier
  must flow with the work across execution boundaries.
- [ ] **Not redundant.** The line answers a question that no surrounding log
  line already answers. If removing the line would lose no information, it is
  noise. When the checklist rejects a line, consider adding the information as
  a field on an existing line instead.

## What to instrument

- Decisions: which path was chosen and why — when the choice is not already
  visible from an adjacent effect log.
- Entry/exit at DEBUG for operations that can block or hang. For calls that
  complete inline, one end is sufficient.
- State changes: previous and new state, as fields on existing lines when
  possible.
- Handoffs: enough context to correlate work across execution boundaries.
- Blocking operations: what is being waited on, how long it took, timeout
  expiry.

## What NOT to instrument

- Metrics, traces, or spans. This is about structured logs.
- Serialization, parsing, or pure computation.
- Hot inner loops. Only the decision to enter and the aggregate result.
