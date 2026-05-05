---
name: inquisition
description: Root out heresies against the design. The implementation is guilty until proven justified. Load when verifying a codebase against its designs.
---

# The Inquisition

Conduct an inquisition. An inquisitor is an adversary to the implementation. Every line of code is suspect until the
designs justify its existence. What the design does not demand, the code should not contain.

Four charges:

1. **Absence** — the design mandates behavior the code doesn't implement or defend.
2. **Heresy** — the code implements behavior the design doesn't sanction.
3. **Schism** — the code implements the design under names the design doesn't use.
4. **Excess** — the code implements the design but with unjustified complexity.

It works through **Understand → Analyze → Judge → Remediate**: understand the designs, measure the code,
bring charges, remediate them. Fix by severity, descending. Each iteration addresses one coherent
cluster — remediate, return to Analyze, repeat. Stop when charges are resolved or blocked on user input.

## 1. Understand

Read ALL design documents before anything else. They typically live at `docs/design.md`, `docs/*.md`, or `DESIGN.md` in the repository root. Look for files that describe system behavior and architecture. If no design documents exist, surface this to the user before proceeding. When designs are ambiguous or clearly stale, surface this to the user — don't treat a stale design as gospel.

Build the mental model of intended architecture. Know what complexity you EXPECT to see and where. Every judgment in later steps flows from this model.

## 2. Analyze

```bash
inquisitor ./path/to/packages/...
```

The tool's output is self-documenting — it opens with a glossary defining every metric, followed by medians, a package listing, then metric sections showing notable values. Sections with research-backed thresholds only fire when values exceed them; sections without thresholds always fire. The output ends with a Tests section listing all test functions grouped by package — this is the inventory for reasoning about whether component interactions are defended. Read the full output before proceeding to Judge.

## 3. Judge

Verification is structured around the four charges.

You are the adversary. The implementation must defend itself with evidence from the designs.
Complexity that cannot cite chapter and verse from a design document is guilty.

### Build the concept map

The concept map is the primary deliverable. It connects designs to code to metrics to tests and reveals all four charges simultaneously.

For each design concept:
1. Find packages, types, and functions whose names correspond to the concept.
2. Check whether the metrics match the design's intent for that concept.
3. Find tests across the entire Tests section whose names indicate they exercise this concept's behavior — regardless of which package the test lives in.
4. Record the mapping.
5. Check for schism — does the code use the same terms as the design? If the design says "rate limiter" and the code says "throttler", the code has a schism. Do the test names use the design's vocabulary?

Then scan for unmapped code — packages with significant complexity (high lines, high Ce, many exports) that no design concept claims.

| Design Concept | Code (by name) | Names | Metrics | Tests | Status |
|---|---|---|---|---|---|
| *concept from design* | `pkg/...` | ✓ matches | *metrics* | TestFoo, TestBar | ✓ |
| *concept from design* | `pkg/...` | ✓ matches | *metrics* | — | ABSENCE (undefended) |
| *concept from design* | — | — | — | — | ABSENCE |
| — | `pkg/...` | — | *metrics* | TestBaz | HERESY |
| *concept from design* | `pkg/...` | SCHISM: design says X, code says Y | *metrics* | TestY (schism) | SCHISM |

ABSENCE rows reveal Absence — including design concepts that have implementation but no tests defending them. Unmapped code reveals Heresy — and tests defending heretical code must be removed alongside it. Naming mismatches reveal Schism — in code AND in test names. Mismatched metrics reveal Excess — in implementation AND in test complexity.

### Assess defense

After building the concept map, reason about whether the design is adequately defended. For every design concept that has implementation (non-ABSENCE rows), ask: if this behavior regressed, would a test catch it?

Match tests to concepts by what behavior they exercise, not by where they live. A test in `e2e/` can defend a concept in `pkg/server`. A test named `TestGracefulShutdown` defends the shutdown concept regardless of its package. Read test names as behavioral descriptions and map them to design concepts across the full Tests section.

When a test name is ambiguous (generic names like `TestProcess`, high cog suggesting table-driven cases), do not assume coverage — treat the concept as potentially undefended and note the ambiguity in the verdict.

Think at the concept level, not the function level. The question is never "does function X have a test?" — it's "does the design's concept Y have a test that would catch regression in the behavior Y describes?" The design describes interactions between components. A concept may have code in multiple packages but need only one test that exercises the interaction end-to-end.

For each undefended concept, consider the severity. A critical invariant without a test is more dangerous than an edge case without one. The design's emphasis tells you what matters — concepts the design spends more words on are more important to defend.

Mark undefended concepts as ABSENCE in the concept map's Status column. These are concepts where the implementation exists but can silently regress.

### Absence

**What to look for**: The design describes behavior but you cannot find corresponding complexity in the codebase. Or: the design concept is implemented but no test defends it — it can silently regress.

**How metrics help**: Use the package listing and medians to see where complexity concentrates. If the design describes a complex subsystem, you expect to find corresponding complexity — substantial functions, types, lines. If you find nothing, the implementation is absent.

**How the Tests section helps**: Cross-reference the concept map's Tests column. A design concept with implementation but no corresponding tests in the Tests section is undefended. This is surfaced by the "Assess defense" step above.

### Heresy

**What to look for**: Metrics show complexity that the design doesn't account for.

**How metrics help**: Look at the package listing — which packages have lots of lines, high Ce, many exports? Do they map to design concepts? Look at threshold violations — do the functions and types exceeding limits correspond to design-described behavior? If a package has high complexity but no design concept claims it, the code implements something nobody asked for.

**How the Tests section helps**: Tests that defend heretical behavior are themselves heresy — they preserve code that shouldn't exist. When identifying heretical code, check whether tests exist for it. Those tests must be removed alongside the code they defend.

### Schism

**What to look for**: The concept map's names column. The design establishes canonical language. Code that implements the same concept under a different name creates a schism — an unnecessary division between design and implementation that makes the design untraceable.

**How the concept map reveals it**: For each row, compare the design's term against the code's identifier. Same behavior, different name = schism.

**How the Tests section helps**: Test names are part of the schism. If the design says "rate limiter" and the test says `TestThrottler`, the test perpetuates the schism. Test names should use the design's vocabulary.

**Why it's essential**: Without naming fidelity, design and code drift apart until the design becomes untraceable.

### Excess

**What to look for**: Code maps to design concepts but metrics show wrong structure.

**Structural roles.** The metrics reveal what role code plays in the architecture — stable foundation vs volatile leaf, coordinator vs calculator, focused type vs entangled god object. Compare the role the design describes against the role the metrics reveal. The tool's glossary explains what each metric signals about architectural role.

**Proportionality.** Complexity is justified when proportional to what the design describes. Count the concepts the design names for a given function or type — the metric values should scale with that count. If they don't, the implementation exceeds its mandate.

**Test excess.** The Tests section shows cog and lines for each test. A test with disproportionate complexity for the concept it defends is excess in the test itself. Tests should be simple proofs — if a test is harder to understand than the code it exercises, it needs simplification.

**Cross-level reasoning.** Metrics at different levels compose. Package metrics reveal the whole; function metrics reveal which specific pieces bear the cost.

**Failure modes for this section:**
- Flagging high Ca on a library or high Ce on a leaf. These are correct metrics for correct architecture.
- Splitting a type when the design describes it as one concept with multiple facets.
- Assuming all complexity is bad. Some designs ARE complex. High complexity might be correct.
- Matching names without matching semantics. A name can match a design concept while the code does something completely different.
- Confusing Heresy with Excess. If a function implements unsanctioned behavior, that's Heresy — regardless of the function's complexity metrics. Excess means the right behavior at the wrong complexity.

### Produce verdicts

For every item worth reporting:

For items flagged by the tool (Excess, Heresy):

```
### [package/type/function name] — [VERDICT]

**Candidate**: [exact line from the tool output]
**Design section**: [document name] § [section heading], or "None"
**Design says**: "[exact quote, max 2 sentences]" or "Not in any design document."
**Protection**: [tests defending this concept from the Tests section, or "None"]
**The gap**: [which charge and why]
```

For items found through concept mapping (Absence):

```
### [design concept] — ABSENCE

**Design section**: [document name] § [section heading]
**Design says**: "[exact quote describing the expected behavior]"
**Evidence of absence**: [what you searched for and didn't find]
**Protection**: [tests that should defend this concept but don't exist]
```

For items found through naming mismatch (Schism):

```
### [code symbol] — SCHISM

**Design section**: [document name] § [section heading]
**Design says**: "[term the design uses for this concept]"
**Code says**: "[term the code uses instead]"
**Tests say**: "[term the tests use, if different from design]"
**The gap**: Design concept [X] is implemented as [Y]. Rename to match the design.
```

Four charges (one per item):
- **ABSENCE** — design describes behavior the code doesn't implement or defend.
- **HERESY** — implements behavior the design doesn't sanction.
- **SCHISM** — implements the design under names the design doesn't use.
- **EXCESS** — more complex than the design requires (in code or tests).

Or acquitted:
- **JUSTIFIED** — a specific design requirement demands this complexity. Cite it.

Order: ABSENCE first, then HERESY, then SCHISM, then EXCESS, then JUSTIFIED.

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
- Start every SCHISM verdict from a naming mismatch in the concept map.
- Quote the design when the code should match it.
- Quote the design's absence when the code has no design backing.
- When a type shows multiple responsibilities, name the groups and what separate types they suggest.
- When a function exceeds complexity thresholds, identify which decisions the design does not describe.

## 4. Remediate

Each charge has a natural remedy.

### Absence → Implement

The design mandates behavior the code doesn't deliver. Write it. The design tells you what to build — the concept map tells you where it belongs in the architecture. Add a test that defends the concept against future regression. Do not ask — the design already decided.

### Heresy → Cut or Canonize

Code exists that no design sanctions. Two paths:
- **Cut** — delete the code AND its tests. Tests that defend heresy preserve heresy.
- **Canonize** — if the code is valuable, update the design to sanction it. Present to the user. Do not unilaterally decide.

### Schism → Rename

Heal the schism. Rename the symbol to match the design's term. Rename the tests to match. Design, code, and tests should speak one language. Do not ask — the design already named it.

### Excess → Simplify

The code implements the design but with wrong structure or disproportionate complexity. The tool's output describes what each metric implies — use that guidance. Simplify overly complex tests alongside the code — a test should be a simple proof, not a second system. Name every refactored piece after concepts the design uses. Do not ask — the design already scoped it.



