---
name: reconciling-code-instrumentation
description: >
  Reconcile code instrumentation against the system's decision points.
  Load when adding or reviewing diagnostic logging.
---

# Instrumenting Code

You should be able to reconstruct what the system did and why from its logs
alone.

## Log levels

- **ERROR** — something went wrong. Errors drive alerts.
- **INFO** — the system acted on the outside world. Logged once, after the
  effect.
- **DEBUG** — why the system did what it did. Off by default.

## Structured context

Every log line must carry enough structured fields to filter to a specific
operation and component. Set context at scope boundaries — every log line within
that scope inherits it.

Handoffs break the call stack. A correlation identifier must flow with the work
across execution boundaries.

## Redundancy gate

A log line must answer a question that no surrounding log line already answers.
If removing the line would lose no information, it is noise. If the gate rejects
a line: add the information as a field on an existing line, or emit nothing.

Signs of a redundant log line:

- An aggregate (count or list) precedes a loop whose iterations are individually
  logged. The aggregate is derivable.
- A non-event is logged (e.g., "skipped X") when the action log's absence
  already communicates the skip.
- A separate log line carries information that belongs as a field on an existing
  log line for the same event.
- Both ends of a call that completes inline are logged. One end is sufficient.

Example. Before (two lines for one event):

    DEBUG creating new informer  gvr=apps/v1/deployments owner=graph/ns/foo
    DEBUG informer started       gvr=apps/v1/deployments

After (one line, field added):

    DEBUG informer started       gvr=apps/v1/deployments owner=graph/ns/foo

The `owner` field carries the unique information. The entry line is gone — the
call completes inline and one end is sufficient.

## Decisions and handoffs

Instrument decisions and handoffs, not computation. Decisions are where the
system chose a path. Handoffs are where work moves between execution contexts.

Signs of well-instrumented code:

- The log explains which path was chosen and why alternatives were not.
- Entry and exit are both logged at DEBUG for operations that can block or hang
  — a missing exit identifies where the system is stuck. For calls that complete
  inline, one end is sufficient (see redundancy gate).
- State changes record previous and new state.
- Enough context is present to correlate work that crosses execution boundaries.
- Blocking operations record what is being waited on and how long it took.
  Timeout expiry is logged, not just success.
- Aggregated work is logged as a set before processing begins, when individual
  items are not individually logged during processing.
- Hot inner loops are not instrumented — only the decision to enter the loop and
  the aggregate result.

## What this skill does NOT do

- Add metrics, traces, or spans. This is about structured logs.
- Instrument serialization, parsing, or pure computation.

## Workflow

1. **List decision points.** Read the code and identify decisions (path
   choices), handoffs (work crossing execution boundaries), state machines,
   and blocking operations. Create a TODO per decision point.

2. **Check visibility.** For each TODO, check: is the outcome already visible
   from existing logs? Mark TODOs where the outcome is invisible — these are
   the candidates. Cancel the rest.

3. **Gate each candidate.** For each surviving TODO, draft the log line, then
   apply the redundancy gate against the surrounding context. If the gate
   rejects it, cancel the TODO. If a field on an existing line suffices,
   rewrite the TODO as a field addition.

4. **Check levels.** Assign the level per § Log levels.

5. **Write the surviving lines.**

6. **Verify.** Exercise the instrumented code paths through tests. The logs
   must answer:
   1. Why did this operation start?
   2. For each unit of work: was it acted on, skipped, or blocked? Why?
   3. What was the outcome and duration?

   If any question cannot be answered, the instrumentation is incomplete. If
   the answer appears in more than one log line, the instrumentation has
   redundancy.
