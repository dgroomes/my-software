# deduplicator

Deduplicate repeated blocks of text.


## Overview

I want to deduplicate text so that I can have smaller LLM prompts. Consider the use-case of copying a whole codebase,
or large swaths of a huge codebase. There is often a license block that appears in block comments in every file of the
source code:

```java
/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package some.open.source.project;

public final class SomeClass { /* ... */ }
```

This particular license block takes up around 160 tokens. There are over 5,000 occurrences of this license block in the
[Apache Kafka codebase](https://github.com/apache/kafka) which equates to over 800,000 tokens and is way over the
typical maximum context length of models from OpenAI, Anthropic, Meta, etc.

The `deduplicator` tool will confine large repeated text blocks to only their first occurrence and thus save many
precious tokens in a prompt. There's no value in repeating a text snippet that is already present in the context. We can
instead refer to it by something like an alias, a file name plus line number, or a description.


## Algorithm

This is hard stuff. The vision is an algorithmically efficient implementation—linear time, not quadratic. This
efficiency comes at the cost of algorithmic complexity. The implementation uses the **SA-IS (Suffix Array Induced
Sorting)** algorithm which runs in **O(n)** time and space. This is the optimal algorithm for suffix array construction.

The deduplication pipeline:

1. **SA-IS**: Build a suffix array in linear time
2. **Kasai's Algorithm**: Compute the LCP (Longest Common Prefix) array in linear time
3. **Range Consolidation**: Use a TreeMap to efficiently merge overlapping duplicate ranges on-the-fly, avoiding
   millions of object allocations

I relied on LLMs (Claude) to help me understand and implement the SA-IS algorithm. The implementation is a Kotlin port
of the [sa-is](https://github.com/oguzbilgener/sa-is) Rust library, which itself is derived from the Chromium project's
SA-IS implementation. See `LICENSES/SA-IS.txt` for the license.


## Instructions

1. Pre-requisite: Java 21
2. Activate the Nushell overlay
   * ```nushell
     do activate
     ```
3. Run the tests
   * ```nushell
     do test
     ```
4. Build the program distribution
   * ```nushell
     do build
     ```
5. Try it out
   * ```nushell
     "hihi" | do run --min-length 2
     ```
   * The output will be the following.
   * ```text
     hi
     ```
6. Try other combinations, and experiment
   * ```nushell
     "hihi" | do run --min-length 3
     "hello hello hi" | do run --min-length 3
     ```
7. Install the program distribution with a symlink
   * ```nushell
      do install
      ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [ ] Consider biasing to lines as the boundary for deduplication. I'm not sure how this would look, but in practice
  across-line deduplication makes things confusing to read. In the normal case, we just lose the partial final line's
  worth of deduplication? Because I'm authoring the code, I have the flexibility to do this.
* [ ] Multi-document support.
* [x] DONE Implement SA-IS algorithm for O(n) suffix array construction
* [x] DONE Implement Kasai's algorithm for O(n) LCP array construction
* [ ] Consider how to ID and reference deduplicated text
* [ ] Get serious about understanding encoding (UTF-16 codepoints, byte sequences, etc.)
* [ ] Make it faster. In my other branch, Opus 4.5 was able to get performacne down from 20 seconds to around 5 seconds
  on the Kafka source. Bring in some of those optimizations. Currently we're at 13 seconds. 


## References

* [Wikipedia: *Suffix array*](https://en.wikipedia.org/wiki/Suffix_array)
* [Wikipedia: *LCP array*](https://en.wikipedia.org/wiki/LCP_array)
* [Stanford CS166 Lecture Notes on SA-IS](https://web.stanford.edu/class/archive/cs/cs166/cs166.1196/lectures/04/Small04.pdf)
* [Google Research: deduplicate-text-datasets](https://github.com/google-research/deduplicate-text-datasets)
* [sa-is (Rust)](https://github.com/oguzbilgener/sa-is) - Rust port of Chrome's SA-IS implementation
