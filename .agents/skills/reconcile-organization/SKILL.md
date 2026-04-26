---
name: reconcile-organization
description: Reconcile code structure against its architecture by drawing boundaries at the right levels — packages, files, structs, functions.
---

# Organizing Code

You should be able to understand the architecture by reading the package names. You should be able
to understand the component interactions by reading the imports. If you have to read thousands of
lines to understand either, the code's structure is hiding its architecture.

Good boundaries make modular code. Bad boundaries make a disaster. The job is to find the
boundaries that already exist in the system — in the designs and in the code — verify they're
real, and harden them.

Each invocation of this skill works one level. Make it clean, stop. The next invocation goes
deeper.

## What makes a boundary real

Signs of a real boundary:

- There is a **concrete type at the interface** — one side produces it, the other consumes it. If
  you can name this type, the boundary has a shape. If you can't, it probably isn't real.
- The **contract is narrow** — the consumer uses a small surface of the producer. Methods or fields
  the consumer doesn't use suggest the contract exposes too much.
- The **dependencies are clean** — each side uses the other through the interface, not around it.
  If the consumer reads internal fields, duplicates logic that exists inside the boundary, or needs
  to understand the producer's implementation to use it correctly, the abstraction may be leaking.
- The **two sides change independently** — a change to one side's internals does not typically
  require a change to the other's. If they usually change in lockstep, consider whether it's
  really one component.

The more of these a seam has, the stronger the boundary. When they're all absent, forcing a split
creates interfaces with one implementation, parameters threaded everywhere, and import tangles.
When some are present and others aren't, use judgment — the cost of the split versus the cost of
the tangle.

## Levels of organization

The signs above are strongest at the package level. Within a package, lighter-touch heuristics
apply:

- **Files** for concepts. A file with two unrelated concepts is two files. Each file's name tells
  you what's inside.
- **Structs** for data that travels together. A function with 10 parameters where 6 are always
  passed together is asking for a struct. A struct with fields from two different lifecycles is
  two structs.
- **Functions** for single operations. A function whose name requires "and" is usually two
  functions — unless the caller must never call one without the other.

## Procedure

Work one level at a time. Make the current level clean before going deeper.

### 1. Understand the system

Read the design documents, the code, whatever it takes to understand the architecture — what the
components are, how they interact, what they produce and consume. You cannot find boundaries in a
system you don't understand.

### 2. Find the boundaries

Apply the boundary signs to every seam you find. Look for: types referenced by multiple unrelated
call chains, files with imports from conceptually separate domains, long files with sections
separated by comment headers, functions that take parameters from different lifecycles.

When designs and code disagree about where a boundary is — the design declares a component the
code doesn't separate, or the code has a seam the design doesn't mention — that's a finding.
Document it.

### 3. Harden them

Extract in dependency order — if B depends on A, extract A first so B compiles against it. Name
each package so a reader understands the architecture without opening a file — the name is the
boundary.

Move functions. Compile. Test. Compiler errors tell you where the code's actual structure
disagrees with the boundary you're drawing.

### 4. Verify

After each change:
- The code compiles and tests pass.
- The import graph is acyclic.
- Every boundary still looks right against the signs in "What makes a boundary real."

### 5. Stop

The current level is clean when every seam identified in step 2 has been either hardened or
documented as a finding, and no function or type straddles two of the resulting boundaries. Do not
descend into sub-boundaries in the same pass. The next invocation goes one level deeper. Each
deeper level takes less effort because the upper level is already clean.

## Escape hatch

If an extraction produces more violations than clean separations, the boundary probably isn't
worth it at this point. Either the design is aspirational, or the code has drifted. Document
what you found and stop. Revisit after the design or the code changes.

## What this skill does NOT do

- **Redesign algorithms.** Code moves; logic doesn't change.
- **Add abstractions speculatively.** Interfaces only where the extraction demands them.
- **Invent boundaries.** If neither the designs nor the code declare a boundary, don't create one.
- **Ignore performance.** Boundaries have performance implications — an interface type that forces
  copies on the hot path, a package split that prevents inlining, a struct extraction that changes
  memory layout. Document performance findings. Don't optimize in this pass.

## Documenting findings

    ### Finding: <short description>
    **Boundary**: X → Y
    **Evidence**: <what you observed — a dependency that crosses the boundary, a type used by
     both sides, a function that needs access to both components' internals>
    **Implication**: <what this means for the architecture>
    **Action**: fix now / defer to design review / note and continue
