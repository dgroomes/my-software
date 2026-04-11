# SA-IS multi-PR implementation plan

This document lays out a layered implementation plan centered on **SA-IS**.

The main goal is to go deep on suffix-array construction itself:

* understand the SA-IS algorithm well
* document it in an implementation-free place
* create traces and visualizations that make it legible
* build small, reviewable implementations and correctness checks around it

The Kotlin deduplicator is still relevant, but it is no longer the center of the plan. It is one application of SA-IS,
not the organizing concept for the work. This plan is inspired by the exploratory changes in the branch `cursor/deduplicator-harness-b67f`. That exploratory work was broader and covered the full deduplication use-case but we've since narrowed it down to a more focused core (SA-IS).


## Summary

The effort has four broad concerns:

1. **SA-IS use-case and algorithm knowledge**
   * what SA-IS is
   * why suffix arrays matter
   * references, examples, and implementation registry
2. **SA-IS trace protocol**
   * a language-agnostic serialized contract for SA-IS traces
   * sample traces and golden examples
3. **SA-IS implementations**
   * a Kotlin SA-IS core module
   * a Kotlin SA-IS trace-output module
   * later, a TypeScript SA-IS implementation
4. **Tooling**
   * visualization based on the output from a trace
   * SA-IS TCK


## Early note

One early note is to treat Nushell command validation as a hard acceptance criterion for every PR that changes a README.

If a README command is added or edited, it must be runnable in Cursor Cloud. This includes installing/configuring
Nushell as needed during validation. If it becomes useful to commit Nushell installation and config instructions, add
those to the backstage README specifically with a note for Cursor Cloud agent.


## Desired future directory shape

This is the target shape, not an instruction to implement all at once.

```text
/workspace
  sa-is/                               # algorithm home, not an implementation
    README.md
    references.md
    trace-protocol.md
    examples/
      banana/
      trace-examples/
        banana-suffix-array.ndjson
        banana-induced-sort.ndjson

  java/
    sa-is/                             # Kotlin core implementation only
    sa-is-trace/                       # Kotlin adapter / executable trace output
    deduplicator/                      # consumer of the Kotlin SA-IS module
    sa-is-tck/                         # suffix-array correctness + trace milestones

  javascript/
    sa-is-visualizer/                  # TS/React/Bun visualization app
    sa-is/                             # TS implementation later
```

Notes:

* `sa-is/` at the repo root is the implementation-free home for the algorithm.
* `java/sa-is/` is the Kotlin core algorithm module.
* `java/sa-is-trace/` is the Kotlin adapter layer for trace emission / serialization and may carry incidental
  dependencies like Jackson.
* `java/deduplicator/` consumes `java/sa-is/` and remains one application of the algorithm.
* The visualizer should be about making SA-IS understandable first, not about wiring together a live application stack.


## Architectural rules

### 1. Keep SA-IS separate from deduplicator rewrite semantics

The main thing I want to understand is suffix-array construction via SA-IS.

That means the docs, examples, traces, and visualizations should focus on:

* S/L classification
* LMS indices
* bucket placement
* induced sorting
* reduced problems / recursion
* final suffix array

Not on:

* preferred duplicate-removal policies
* prompt-compression string rewriting
* deduplicated output formatting

Those latter things are downstream consumers of the suffix-array work and should stay downstream.


### 2. The top-level SA-IS docs are implementation-free

The language-agnostic explanation of SA-IS should live under the top-level `sa-is/` directory.

That directory should carry:

* the prose explanation
* the lecture/reference links
* worked examples
* the implementation registry
* the tooling registry
* the trace protocol, once we have one

It should not start life as a home for Kotlin-specific or TypeScript-specific code. I want this to reference implementations like <https://github.com/google-research/deduplicate-text-datasets>. In fact we want to extract some of the SA-IS commentary from `java/deduplicator` and have `java/deduplicator` make reference to the ../sa-is directory to point the reader to understand SA-IS.


### 3. Keep the Kotlin SA-IS core free of incidental dependencies

`java/sa-is/` should be the minimal Kotlin implementation of the algorithm.

It should own:

* suffix-array construction
* core domain types needed by the algorithm
* any algorithm-local trace interfaces, if needed

It should not own:

* Jackson
* NDJSON / JSON schema types
* CLI-only concerns
* visualization-specific concerns

The point is to keep the core module reusable and intellectually clean.


### 4. Put trace output in a separate Kotlin module

`java/sa-is-trace/` should depend on `java/sa-is/`.

It is the right place for:

* translating core SA-IS events into a trace protocol
* emitting NDJSON / JSON
* carrying Jackson or other serialization dependencies
* shipping a trace-oriented executable mode, if useful

This keeps the core algorithm module free of incidental concerns while still letting us build rich trace tooling.


### 5. Visualization consumes static SA-IS traces first

The visualization app must not start life by shelling out to the Kotlin implementation.

It should first:

* load static sample traces from files
* animate them
* prove the UX and the visual model

Only later should it gain optional support for loading traces generated by a real implementation.


### 6. The TCK is for SA-IS, not for deduplicator output semantics

The TCK should validate:

* suffix-array correctness
* selected trace milestones
* sample-trace compatibility

It should not validate:

* final deduplicated output text
* duplicate range consolidation policy
* prompt-oriented rewrite semantics

Those are real questions, but they are separate questions.


## PR plan

This is the proposed layered PR sequence.


### PR 1: Create an implementation-free SA-IS home

**Goal**

Create a non-implementation home for the SA-IS problem, references, and examples.

**Introduce**

* `/workspace/sa-is/README.md`
* `/workspace/sa-is/references.md`
* possibly `/workspace/sa-is/examples/`

**Contents**

* what a suffix array is
* why SA-IS exists
* high-level walkthrough of the algorithm
* references, especially the lecture PDF
* implementation registry
* tooling registry

**Move / reshape**

* trim `java/deduplicator/README.md` back to implementation-specific content
* leave only small notes there about related prior art

**Acceptance**

* root README index updated appropriately
* all README commands, if any, actually run in Cursor Cloud


### PR 2: Extract a Kotlin `sa-is` core module

**Goal**

Create a Kotlin module that implements SA-IS directly and can be reused by other modules.

**Introduce**

* `/workspace/java/sa-is/`

**Important**

* the module should stay light on dependencies
* it should not depend on Jackson
* it should expose the algorithm in a way that `java/deduplicator/` can consume

**Acceptance**

* `java/deduplicator/` consumes `java/sa-is/` instead of carrying the SA-IS implementation directly
* focused tests validate suffix-array correctness


### PR 3: Spec out the SA-IS trace protocol and include sample traces

**Goal**

Create a language-agnostic spec for SA-IS trace events, with sample NDJSON traces checked in.

**Introduce**

* `/workspace/sa-is/trace-protocol.md`
* `/workspace/sa-is/examples/trace-examples/`
  * `banana-suffix-array.ndjson`
  * `banana-induced-sort.ndjson`

**Protocol scope**

At minimum specify:

* transport format: NDJSON
* event ordering expectations
* required / optional fields by event kind
* semantics of:
  * `phase`
  * `depth`
  * `input`
  * `classification`
  * `lmsIndices`
  * `buckets`
  * `suffixArray`
  * `reducedProblem`

**Acceptance**

* sample traces are treated as golden fixtures
* the visualization PR can consume these files without requiring any implementation


### PR 4: Implement Kotlin `sa-is-trace`

**Goal**

Create a Kotlin module that consumes `java/sa-is/` and emits SA-IS trace output.

**Introduce**

* `/workspace/java/sa-is-trace/`

**Important**

* `java/sa-is/` stays free of Jackson and wire-format concerns
* `java/sa-is-trace/` may depend on Jackson
* this module is the bridge from core algorithm execution to the trace protocol

**Acceptance**

* the module can emit traces compatible with the protocol from PR 3
* sample traces can be regenerated from the Kotlin implementation


### PR 5: Visualization in `javascript/` using sample SA-IS traces

**Goal**

Build the trace visualization as a TS/React/Bun app using the sample NDJSON traces from PR 3.

**Introduce**

* `/workspace/javascript/sa-is-visualizer/`

**Features**

* load one sample trace at a time
* playback controls
* panels for:
  * input symbols
  * S/L classification
  * LMS markers
  * buckets
  * suffix-array view
  * event narration

**Important**

* Do not require the Kotlin implementation yet.
* This PR is about understanding and UX.

**Acceptance**

* README commands run in Cursor Cloud
* browser/manual demo artifact produced


### PR 6: Implement an SA-IS TCK

**Goal**

Create a black-box TCK that validates suffix-array outputs and selected trace milestones.

**Introduce**

* `java/sa-is-tck/`

**Validate**

* suffix array correctness on known examples
* selected trace milestones
* sample-trace compatibility

**Explicitly exclude**

* deduplicated output strings
* duplicate range semantics
* prompt-compression behavior

**Acceptance**

* the Kotlin implementation passes the SA-IS TCK
* the TCK does not depend on Kotlin implementation internals in process


### PR 7: Implement a TypeScript SA-IS algorithm

**Goal**

After the docs, traces, visualization, and TCK are stable, add a TypeScript SA-IS implementation.

**Introduce**

* `/workspace/javascript/sa-is/`

**Requirements**

* pass the SA-IS TCK
* optionally emit compatible SA-IS traces

**Important**

This should be much easier because:

* the algorithm is already documented
* the trace protocol is already specified
* the visualizer already exists
* the TCK already defines correctness


## Concrete tasks within each layer

### Shared SA-IS docs tasks

- [ ] Create `/workspace/sa-is/README.md`
- [ ] Move SA-IS learning material out of `java/deduplicator/README.md`
- [ ] Move lecture/reference links into the SA-IS directory
- [ ] Add implementation registry section
- [ ] Add tooling registry section
- [ ] Update root README index


### Trace protocol tasks

- [ ] Write event catalog
- [ ] Define required vs optional fields
- [ ] Define NDJSON framing rules
- [ ] Define phase semantics
- [ ] Check in golden sample trace files
- [ ] Add protocol evolution notes


### Kotlin SA-IS core tasks

- [ ] Create `java/sa-is/`
- [ ] Move or extract SA-IS implementation there
- [ ] Keep the module free of Jackson
- [ ] Expose a clean API for suffix-array construction
- [ ] Make `java/deduplicator/` consume it


### Kotlin SA-IS trace tasks

- [ ] Create `java/sa-is-trace/`
- [ ] Add Jackson there if needed
- [ ] Instrument S/L classification
- [ ] Instrument LMS detection
- [ ] Instrument bucket placement
- [ ] Instrument induced sorting
- [ ] Instrument reduced-problem recursion
- [ ] Serialize protocol-compatible trace output


### Visualization tasks

- [ ] Create Bun/TS/React project in `javascript/`
- [ ] Load sample traces
- [ ] Build timeline playback
- [ ] Render classification / LMS / buckets / suffix array
- [ ] Add speed / scrub controls
- [ ] Later add real-trace loading


### SA-IS TCK tasks

- [ ] Validate suffix arrays for known examples
- [ ] Validate selected semantic milestones in traces
- [ ] Validate sample-trace compatibility
- [ ] Keep the tests black-box


## Explicit non-goals for the next PRs

These should be resisted until much later, if ever:

- [ ] Reintroducing a multi-implementation deduplicator plan
- [ ] Creating `deduplicator-tck/`
- [ ] Creating `deduplicator-trace-tck/`
- [ ] Creating `deduplicator-perf/`
- [ ] Implementing a TypeScript deduplicator
- [ ] Settling preferred duplicate-removal semantics in the SA-IS plan itself


## Cursor Cloud / Nushell validation rule

This is still a hard rule for future PRs:

* If a README includes Nushell commands, the implementing agent must:
  * install / configure Nushell if needed
  * run the commands
  * fix the commands or the code until they work


## Suggested next task

The best next session is **PR 1** only:

* create the non-implementation `/workspace/sa-is/` directory
* move SA-IS learning material into it
* trim the implementation README back to implementation-specific content
* update the root README index

Do *not* also spec the trace protocol in that same PR.
