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

Google Research has shared a focused (and fast) [deduplicator implementation in Rust](https://github.com/google-research/deduplicate-text-datasets).
The most common deduplication algorithm, as far as I can tell, uses _suffix arrays_. That's what I want to do and what I
want to learn, but I'm a bit out of my depth so I'm going to iterate from the ground up with some smart LLMs plus the
Google implementation as a reference. Let's see what happens.

My needs are far less constrained than the Google implementation and I should enjoy a simpler implementation. Here are
the differences:

* I'm only going to deduplicate up to a few a megabytes of text, not 750GB.
* I don't need parallelism
* I can use a garbage collected language: Kotlin, instead of Rust (although this type of program is a good target for Rust)
* I don't need to spill to disk. In-memory will be fine.

A constraint I'd like to preserve is preventing a huge memory footprint. Building a suffix array for a document
of N characters is something like `N(N - 1) / 2` in the naive case. For example, the document "funky fiesta fun" is 16
characters long and has the following suffixes:

```text
unky fiesta fun
nky fiesta fun
ky fiesta fun
y fiesta fun
 fiesta fun
fiesta fun
iesta fun
esta fun
sta fun
ta fun
a fun
 fun
fun
un
n
```

This totals 120 characters (`16 * 15 / 2 =  120`). This README.md is around 4,000 characters which turns into 8MB worth
of strings in a suffix array. For a corpus of 1,000 files of similar length, that would be roughly 8GB. That's too much.  

The solution is easy: represent the suffixes as offsets into the original documents. There are even more performance
optimizations that can be made, but I need to not be tempted to go into those. I don't need it.


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

* [x] DONE Scaffold the project
* [x] DONE Write tests.
* [x] DONE First pass implement.
* [x] DONE Install instructions
* [ ] Consider biasing to lines as the boundary for deduplication. I'm not sure how this would look, but in practice
  across-line deduplication makes things confusing to read. In the normal case, we just lose the partial final line's
  worth of deduplication? Because I'm authoring the code, I have the flexibility to do this.
* [ ] Maybe the API needs to be more structured instead of document in and document out. Use JSON. I mean, that's been
  my whole strategy and it's worked so let's do it.
* [ ] Make it space and time efficient. I'm not sure what the status is right, haven't thought about it critically.
* [ ] Consider how to ID and reference deduplicated text.
