---
name: inquisition
description: Root out heresies against the design. The implementation is guilty until proven justified. Load when verifying a codebase against its designs.
---

# The Inquisition

Conduct an inquisition. An inquisitor is an adversary to the implementation. Every line of code is suspect until the
designs justify its existence. The inquisitor does not ask "is this code good?" — it asks "does
the design demand this code?" What the design does not demand, the code should not contain.

Three charges:

1. **Absence** — the design mandates behavior the code doesn't implement.
2. **Heresy** — the code implements behavior the design doesn't sanction.
3. **Excess** — the code implements the design but with unjustified complexity.

It works through **Understand → Analyze → Judge → Remediate**: understand the designs, measure the code,
bring charges, remediate them, repeat until the implementation is the simplest version that satisfies
the designs.

## Terminology

- **Candidates**: Items in threshold sections — values exceeding a known limit.
- **Evidence**: Items in evidence sections — metric values reported without a threshold.
- **Verdicts**: The agent's judgments about whether code is justified by designs.

## 1. Understand

Read ALL design documents before anything else. They typically live at `docs/design.md`, `docs/*.md`, or `DESIGN.md` in the repository root. Look for files that describe system behavior and architecture. If no design documents exist, surface this to the user before proceeding.

Build the mental model of intended architecture. Know what complexity you EXPECT to see and where. Every judgment in later steps flows from this model.

## 2. Analyze

```bash
inquisitor ./path/to/packages/...
```

## 3. Judge

Verification is structured around the three charges.

You are the adversary. The implementation must defend itself with evidence from the designs.
Complexity that cannot cite chapter and verse from a design document is guilty.

### Build the concept map

The concept map is the primary deliverable. It connects designs to code to metrics and reveals all three charges simultaneously.

For each design concept:
1. Find packages, types, and functions whose names correspond to the concept.
2. Check whether the metrics match the design's intent for that concept.
3. Record the mapping.

Then scan for unmapped code — packages with significant complexity (high lines, high Ce, many exports) that no design concept claims.

| Design Concept | Code (by name) | Metrics | Status |
|---|---|---|---|
| *concept from design* | `pkg/...` | *metrics* | ✓ |
| *concept from design* | — | — | ABSENCE |
| — | `pkg/...` | *metrics* | HERESY |
| *concept from design* | `pkg/...` | *metrics* | EXCESS |

ABSENCE rows reveal Absence. Unmapped code reveals Heresy. Mismatched metrics reveal Excess.

### Absence

**What to look for**: The design describes behavior but you cannot find corresponding complexity in the codebase.

**How metrics help**: Use the package listing and medians to see where complexity concentrates. If the design describes a complex subsystem, you expect to find corresponding complexity — substantial functions, types, lines. If you find nothing, the implementation is absent.

### Heresy

**What to look for**: Metrics show complexity that the design doesn't account for.

**How metrics help**: Look at the package listing — which packages have lots of lines, high Ce, many exports? Do they map to design concepts? Look at threshold violations — do the functions and types exceeding limits correspond to design-described behavior? If a package has high complexity but no design concept claims it, the code implements something nobody asked for.

### Excess

**What to look for**: Code maps to design concepts but metrics show wrong structure.

**Structural roles.** The metrics reveal what role code plays in the architecture — stable foundation vs volatile leaf, coordinator vs calculator, focused type vs entangled god object. Compare the role the design describes against the role the metrics reveal. The tool's glossary explains what each metric signals about architectural role.

**Proportionality.** Complexity is justified when proportional to what the design describes. Count the concepts the design names for a given function or type — the metric values should scale with that count. If they don't, the implementation exceeds its mandate.

**Cross-level reasoning.** Metrics at different levels compose. Package metrics reveal the whole; function metrics reveal which specific pieces bear the cost.

**Failure modes for this section:**
- Flagging high Ca on a library or high Ce on a leaf. These are correct metrics for correct architecture.
- Splitting a type when the design describes it as one concept with multiple facets.
- Assuming all complexity is bad. Some designs ARE complex. High complexity might be correct.
- Matching vocabulary without matching semantics. A name can match a design concept while the code does something completely different.

### Produce verdicts

For every item worth reporting:

For items flagged by the tool (Excess, Heresy):

```
### [package/type/function name] — [VERDICT]

**Candidate**: [exact line from the tool output]
**Design section**: [document name] § [section heading], or "None"
**Design says**: "[exact quote, max 2 sentences]" or "Not in any design document."
**The gap**: [which charge and why]
```

For items found through concept mapping (Absence):

```
### [design concept] — ABSENCE

**Design section**: [document name] § [section heading]
**Design says**: "[exact quote describing the expected behavior]"
**Evidence of absence**: [what you searched for and didn't find]
```

Exactly one verdict per item:
- **EXCESS** — more complex than the design requires.
- **HERESY** — implements behavior the design doesn't sanction. Present to user.
- **ABSENCE** — design describes behavior the code doesn't implement. Present to user.
- **JUSTIFIED** — a specific design requirement demands this. Cite it.

Order: ABSENCE first, then EXCESS, then HERESY, then JUSTIFIED.

For large reports, audit the top 10 items per section. If patterns emerge (e.g., all cog violations are in one package), note the pattern rather than writing individual verdicts for each.

### Constraints

You must not:
- Say "complex but necessary" without citing design text.
- Say "handles edge cases" without naming them and checking whether they appear in the design.
- Say "could potentially be simplified" — commit to a verdict.
- Assume the code is correct. The design is correct.

You must:
- Start every EXCESS or HERESY verdict from a line in the tool output.
- Start every ABSENCE verdict from a design document quote.
- Quote the design when the code should match it.
- Quote the design's absence when the code has no design backing.
- When a type shows multiple responsibilities, name the groups and what separate types they suggest.
- When a function exceeds complexity thresholds, identify which decisions the design does not describe.

## 4. Remediate

Each charge has a natural remedy.

### Absence → Implement

The design mandates behavior the code doesn't deliver. Write it. The design tells you what to build — the concept map tells you where it belongs in the architecture.

### Heresy → Cut or Canonize

Code exists that no design sanctions. Two paths:
- **Cut** — delete the code. If nothing in the design demands it, it shouldn't exist.
- **Canonize** — if the code is valuable, update the design to sanction it. Present to the user. Do not unilaterally decide.

### Excess → Simplify

The code implements the design but with wrong structure or disproportionate complexity. The tool's output describes what each metric implies — use that guidance. Name every refactored piece after concepts the design uses.

### Complexity displacement

If simplifying A pushes complexity to B, check whether B is now guilty. If complexity circulates rather than shrinks, it's inherent — re-evaluate as JUSTIFIED and cite the design.

### Scale

Fix by severity, descending. Each iteration addresses one coherent cluster. Don't attempt everything in one pass.

Return to Analyze.

### Convergence

Continue the loop until significant progress has been made — charges are resolved, not just identified. You may be asked to conduct another inquisition later. This is a persistent and iterative process, not a one-time audit.

Within a single session: remediate what you can, present what requires user decision (Heresy, Absence that needs design clarification), and stop when the remaining charges are blocked on external input or the codebase has materially improved.
