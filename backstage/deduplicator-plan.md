# Deduplicator multi-PR implementation plan

This document replans the work that is currently co-mingled on `cursor/deduplicator-harness-b67f` into a sequence of
smaller, layered PRs that can be implemented over multiple sessions.

The Cursor Cloud agent implemented quite the stretch of deduplication functionality, visualization and a "trace" system that I asked it to. It's too much to review and refine altogether, so we need to break it down. The actual trace and visualization is critical for me to understand and "quality gate" before exploding the implementation into other langauges and potentially alternate algorithms. My personal bottleneck is grokking the actual SA-IS algorithm. My goal is to reall grok it. I think that the LLM/agent can deliver something of value, as long as it stays on the rails throughout these tasks. 

The goal is not to preserve the current branch structure. The goal is to preserve the *useful ideas* while changing the
shape of the work to fit a cleaner architecture and a better review sequence.


## Summary

The deduplicator effort now has four broad concerns which should be separated:

1. **The use-case and algorithm knowledge**
   * what problem is being solved
   * how SA-IS and LCP fit into deduplication
   * references, examples, and implementation registry
2. **The trace protocol**
   * a language-agnostic serialized contract for suffix-array/LCP/dedup traces
   * sample traces and golden examples
3. **Implementations**
   * Kotlin core implementation
   * Kotlin trace adapter / JSON adapter
   * later, TypeScript implementation
4. **Tooling**
   * visualization
   * functional TCK
   * trace TCK
   * performance harness

The current branch mixed these together too early. That made it easy to make progress, but it makes review and long-term
maintenance harder.

## Early Note

One early note is to treat Nushell command validation as a hard acceptance criterion for every PR that changes a README. 

If a README command is added or edited, it must be runnable in Cursor Cloud. This includes installing/configuring Nushell as needed during validation. If you find it useful to commit Nushell installation and config instructions, add those to the backstage README specifically with a note for Cursor Cloud agent.


## Desired future directory shape

This is the target shape, not an instruction to implement all at once. Reminder, that '/workspace' is just Cursor Cloud Agent's convention for putting the clone of the repository that's being worked on (in this case, `my-software`).

```text
/workspace
  deduplicator/                        # use-case home, not an implementation
    README.md
    trace-protocol.md
    references.md
    examples/
      corpus-examples/
      trace-examples/
        banana-suffix-array.ndjson
        banana-lcp.ndjson
        banana-banana-deduplicate.ndjson

  java/
    deduplicator/                      # Kotlin core implementation only
    deduplicator-trace/                # Kotlin adapter: trace interface -> NDJSON/JSON
    deduplicator-tck/                  # functional TCK only
    deduplicator-trace-tck/            # trace TCK
    deduplicator-perf/                 # performance harness

  javascript/
    deduplicator-trace-visualizer/     # TS/React/Bun visualization app
    deduplicator/                      # TS implementation later
```

Notes:

* `deduplicator/` at the repo root should become the use-case home because it is not an implementation.
* The current `java/deduplicator-tck/` may initially hold both the functional TCK and the trace TCK, but I recommend
  splitting them once the trace protocol is stable:
  * `java/deduplicator-tck/`
  * `java/deduplicator-trace-tck/`
* The visualization deserves its own directory and should not be embedded into the TCK long-term.


## Architectural rules

### 1. Kotlin core does not know JSON

The Kotlin core implementation must not depend on Jackson or any JSON schema types.

Instead, define a small trace interface inside `java/deduplicator/`, for example:

```text
interface DeduplicationTraceEmitter {
  fun traceStarted(...)
  fun slPartitionBuilt(...)
  fun lmsIndicesFound(...)
  fun inducedSortStarted(...)
  fun inducedSortStep(...)
  fun lmsLabelsComputed(...)
  fun recursiveProblemCreated(...)
  fun suffixArrayCompleted(...)
  fun rankArrayBuilt(...)
  fun lcpStep(...)
  fun lcpCompleted(...)
  fun duplicateGroupFound(...)
  fun duplicateRangesIdentified(...)
  fun duplicateRangesConsolidated(...)
  fun deduplicationCompleted(...)
}
```

Important:

* This interface should use domain types, not serialized transport types.
* Example domain types:
  * `IntArray`
  * `List<IntRange>`
  * `String`
  * `enum class TraceMode`
* The core implementation should accept a nullable emitter:
  * `traceEmitter: DeduplicationTraceEmitter? = null`

Then `java/deduplicator-trace/` should:

* implement `DeduplicationTraceEmitter`
* translate domain events into the protocol schema
* serialize NDJSON / JSON using Jackson
* wire the executable mode:
  * `deduplicator trace suffix-array`
  * `deduplicator trace lcp`
  * `deduplicator trace deduplicate`

This is the clean architecture boundary.


### 2. Protocol types belong outside the Kotlin core

The language-agnostic protocol should be defined in prose and examples under the non-implementation use-case directory.

Optionally, a small shared helper module may exist in Java/Kotlin for:

* reading/writing NDJSON
* deserializing protocol events for TCKs

But that helper module should represent the **protocol adapter side**, not the Kotlin core domain.


### 3. Visualization consumes protocol samples

The visualization app must not start life by shelling out to the Kotlin implementation.

It should first:

* load static sample traces from files
* animate them
* prove the UX and the visual model

Only later should it gain optional support for loading traces generated by a real implementation.


### 4. TCKs stay black-box

The functional TCK and the trace TCK should continue to launch executables out of process.

The TCKs should never:

* link directly to `java/deduplicator`
* call Kotlin implementation methods in process
* derive correctness from internal classes


## PR plan

This is the proposed layered PR sequence.


### PR 1: Consolidate deduplication use-case in its own directory

**Goal**

Create a non-implementation home for the deduplication problem and SA-IS learning material.

**Introduce**

* `/workspace/deduplicator/README.md`
* `/workspace/deduplicator/references.md`
* possibly `/workspace/deduplicator/examples/`

**Contents**

* problem statement: deduplicating repeated text blocks for prompt compression
* general explanation of suffix arrays, SA-IS, and LCP
* list of implementations that exist in `my-software`
* list of tooling that exists or is planned
* references moved out of `java/deduplicator/README.md`

**Move/reshape**

* take general use-case prose out of `java/deduplicator/README.md`
* leave `java/deduplicator/README.md` implementation-specific

**Acceptance**

* root README index updated appropriately
* all README commands, if any, actually run in Cursor Cloud


### PR 2: Spec out the trace protocol and include sample traces

**Goal**

Create a language-agnostic spec for trace events, with sample NDJSON traces checked in.

**Introduce**

* `/workspace/deduplicator/trace-protocol.md`
* `/workspace/deduplicator/examples/trace-examples/`
  * `banana-suffix-array.ndjson`
  * `banana-lcp.ndjson`
  * `banana-banana-deduplicate.ndjson`

**Protocol scope**

At minimum specify:

* transport format: NDJSON
* event ordering expectations
* `mode`
  * `suffix-array`
  * `lcp`
  * `deduplicate`
* required/optional fields by event kind
* semantics of:
  * `depth`
  * `phase`
  * `suffixArray`
  * `suffixArrayView`
  * `lcpArray`
  * `positions`
  * `ranges`
  * `result`

**Recommendation**

Document two layers:

1. **core semantic event model**
2. **wire format**

This makes it easier for implementations to map internal state into the protocol.

**Acceptance**

* sample traces are treated as golden fixtures
* the visualization PR can consume these files without requiring any implementation


### PR 3: Visualization in `javascript/` using sample traces

**Goal**

Build the trace visualization as a TS/React/Bun app using the sample NDJSON traces from PR 2.

**Introduce**

* `/workspace/javascript/deduplicator-trace-visualizer/`

**Tech direction**

* Bun
* TypeScript
* React
* local static sample trace files

**Features**

* load one sample trace at a time
* playback controls
  * play/pause
  * step forward/backward
  * speed
  * timeline scrub
* visual panels for:
  * input tokens
  * suffix array view
  * LCP array
  * event metadata
  * narration / explanation

**Important**

* Do not wire to the Kotlin implementation yet.
* Do not depend on the TCK executable.
* This PR is about the visualization model and UX.

**Acceptance**

* README commands run in Cursor Cloud
* browser/manual demo artifact produced


### PR 4: Implement traces in the Kotlin deduplicator and wire to the visualization

**Goal**

Add trace emission to the Kotlin implementation using a clean interface + adapter split.

**Introduce**

* `java/deduplicator/`
  * internal `DeduplicationTraceEmitter` interface
  * instrumentation of suffix-array/LCP/dedup pipeline
* `java/deduplicator-trace/`
  * Jackson-based adapter
  * executable wiring for trace mode

**Important**

* `java/deduplicator/` does **not** depend on Jackson
* `java/deduplicator-trace/` depends on `java/deduplicator`
* serialization happens only in the adapter module

**Wire-up**

* visualization can now load real traces generated by the Kotlin adapter

**Acceptance**

* sample traces can be regenerated from the implementation, or compared to it
* README commands run in Cursor Cloud
* visualization demo uses a real trace produced by the Kotlin trace adapter


### PR 5: Implement functional TCK by extracting core test cases

**Goal**

Create a black-box functional TCK from the Kotlin implementation tests.

**Introduce / reshape**

* `java/deduplicator-tck/` becomes functional-output-only
* extract cases from Kotlin tests into fixture-driven black-box tests

**Explicitly exclude**

* trace assertions
* trace protocol validation

**Acceptance**

* Kotlin implementation passes the functional TCK
* the functional TCK does not depend on the Kotlin implementation in process


### PR 6: Implement trace TCK and demonstrate compliance

**Goal**

Create a trace-specific TCK that validates protocol compliance and expected algorithm progression.

**Introduce**

* either:
  * a new `java/deduplicator-trace-tck/`
* or temporarily:
  * a second suite inside `java/deduplicator-tck/`

**Validate**

* event ordering
* event kinds
* selected field values
* mode semantics
* sample-trace compatibility

**Recommendation**

Be selective in assertions:

* assert meaningful milestones
* avoid over-constraining fields that are not semantically important

**Acceptance**

* Kotlin trace adapter passes the trace TCK
* compliance is demonstrated by actual executable runs


### PR 7: Implement performance harness and wire to Kotlin deduplicator

**Goal**

Add the reusable performance harness after the functional and trace contracts are already separated.

**Introduce**

* `java/deduplicator-perf/`

**Features**

* black-box executable benchmarking
* workload profiles
* scaling table
* relative speed table
* larger scenarios for multi-second runs

**Acceptance**

* Kotlin implementation benchmarked through the harness
* README commands run in Cursor Cloud
* artifact/log produced


### PR 8: Implement a TypeScript deduplication algorithm

**Goal**

Only after the use-case, protocol, visualization, and both TCKs are stable, add the TypeScript algorithm implementation.

**Introduce**

* `/workspace/javascript/deduplicator/`

**Requirements**

* pass the functional TCK
* pass the trace TCK
* optionally later join the perf harness comparison

**Important**

This PR should be much easier because:

* the use-case is already documented
* the protocol is already specified
* the visualization already exists
* the TCKs already define correctness


## Concrete tasks within each layer

### Shared use-case docs tasks

- [ ] Create `/workspace/deduplicator/README.md`
- [ ] Move general problem statement out of `java/deduplicator/README.md`
- [ ] Move SA-IS/LCP references into the use-case directory
- [ ] Add implementation registry section
- [ ] Add tooling registry section
- [ ] Update root README index


### Trace protocol tasks

- [ ] Write event catalog
- [ ] Define required vs optional fields
- [ ] Define trace mode semantics
- [ ] Define NDJSON framing rules
- [ ] Define example traces
- [ ] Check in golden sample trace files
- [ ] Add protocol evolution notes (versioning or compatibility story)


### Kotlin core trace tasks

- [ ] Define `DeduplicationTraceEmitter` interface in `java/deduplicator`
- [ ] Thread nullable emitter through suffix-array code
- [ ] Thread nullable emitter through LCP code
- [ ] Thread nullable emitter through deduplication range logic
- [ ] Ensure no Jackson imports in core module
- [ ] Add focused core tests around trace callback semantics only if needed


### Kotlin trace adapter tasks

- [ ] Create `java/deduplicator-trace/`
- [ ] Add Jackson dependency there
- [ ] Implement wire-model mapping
- [ ] Serialize NDJSON events
- [ ] Provide CLI mode for trace output
- [ ] Keep process contract black-box friendly


### Visualization tasks

- [ ] Create Bun/TS/React project in `javascript/`
- [ ] Load sample traces
- [ ] Build timeline playback
- [ ] Render tokens / suffix array / LCP / narration
- [ ] Add speed/scrub controls
- [ ] Later add real-trace loading


### Functional TCK tasks

- [ ] Extract black-box output fixtures from Kotlin tests
- [ ] Build executable runner
- [ ] Validate stdout and exit codes
- [ ] Document implementation contract


### Trace TCK tasks

- [ ] Parse NDJSON traces
- [ ] Validate event stream ordering
- [ ] Validate selected semantic milestones
- [ ] Validate per-mode behavior
- [ ] Add golden fixture comparisons where appropriate


### Performance harness tasks

- [ ] Generate deterministic corpora
- [ ] Add workload profiles
- [ ] Add relative comparison table
- [ ] Add scaling ratio table
- [ ] Add longer scenarios


## Explicit non-goals for the next PRs

These should be resisted until the right layer:

- [ ] Reintroducing the TypeScript algorithm implementation before PR 8
- [ ] Embedding JSON protocol types into the Kotlin core module
- [ ] Making the visualization depend on a live implementation before sample traces exist
- [ ] Keeping functional TCK and trace TCK conceptually muddled
- [ ] Expanding performance harness scope before the contracts are stable


## How to treat the current branch work

The current branch contains useful prototypes:

* functional TCK ideas
* trace event vocabulary
* performance harness ideas
* trace visualization concepts
* TypeScript implementation prototype

These should be treated as **reference material**, not as the final PR structure.

Recommended workflow:

1. Keep this branch as a reference branch.
2. Open fresh feature branches for the layered PR sequence.
3. Cherry-pick or manually transplant only the relevant ideas into each PR.
4. Do not try to “salvage” the branch by incrementally reshaping it into the layered stack. That will create review noise.


## Cursor Cloud / Nushell validation rule

This is now a hard rule for future PRs:

* If a README includes Nushell commands, the implementing agent must:
  * install/configure Nushell if needed
  * run the commands
  * fix the commands or the code until they work

This should be called out in future README reviews and PR acceptance checks.


## Suggested next task

The best next session is **PR 1** only:

* create the non-implementation `/workspace/deduplicator/` directory
* move general use-case material into it
* trim the implementation READMEs to implementation-specific content
* update root README/index entries

Do *not* also spec the trace protocol in that same PR.

