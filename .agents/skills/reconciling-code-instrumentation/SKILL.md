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

## Decisions and handoffs

Instrument decisions and handoffs, not computation. Decisions are where the
system chose a path. Handoffs are where work moves between execution contexts.

Signs of well-instrumented code:

- The log explains which path was chosen and why alternatives were not.
- Entry and exit are both logged — a missing exit identifies where the system is
  stuck.
- State changes record previous and new state.
- Enough context is present to correlate work that crosses execution boundaries.
- Blocking operations record what is being waited on and how long it took.
  Timeout expiry is logged, not just success.
- Aggregated work is logged as a set before processing begins.
- Hot inner loops are not instrumented — only the decision to enter the loop and
  the aggregate result.

## What this skill does NOT do

- Add metrics, traces, or spans. This is about structured logs.
- Instrument serialization, parsing, or pure computation.

## Verification

Exercise the instrumented code paths through tests. The logs must answer:

1. Why did this operation start?
2. For each unit of work: was it acted on, skipped, or blocked? Why?
3. What was the outcome and duration?

If any question cannot be answered, the instrumentation is incomplete.
