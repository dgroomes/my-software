# text-condenser

---
**MARKED FOR DELETION**

This was insightful, but a few notes: I'm going to prefer to host LLM inference in a separate process, accessible by the
OpenAI-compatible API. This enables important decoupling. I would rather my agent be in TypeScript or Kotlin, for one.

Also, instead of "text-condenser", I want a more general "study" agent that studies and compresses and indexes a project
Vague, but that's the idea. And I would implement that likely in Kotlin.

---

An LLM-powered tool that rewrites text to be more information-dense. 


## Overview

This tool uses a local LLM to intelligently eliminate token noise while preserving most of the original information in the file. This is not a general purpose compression algorithm. This performs a lossy transformation, but ideally all essential information is preserved. We're relying on the LLM's ability to differentiate noise (syntax, filler words, etc.) from meaningful content.

Like compression algorithms, this tool is especially effective on structured text formats like JSON which have repeated syntax elements (quotes, colons, braces, etc).

I've chosen the word _condenser_ to disambiguate it from compression and summarization:

* This tool is not a _compressor_. Typical text compression algorithms preserve all bits and are not lossy.
* This tool is not a _summarizer_. Summarization always eliminates details for the sake of brevity.
* This tool is a _condenser_. It takes the original text and condenses it down to its essential information. Information loss should be minimal.

The primary use case is reducing token counts of files to fit within LLM context windows. LLMs excel at reading fuzzy,
natural language representations and don't require perfect syntax preservation. By condensing files this way, we can fit
more meaningful content into limited context windows.

The use-case of "compressing prompts for LLMs" is widely explored. I'm trying to figure out if I can use some of these other other tools directly or if I'm better off implementing core concepts into my own tool. Examples include:

* [CompressGPT](https://github.com/yasyf/compress-gpt)
* [LLM Text Compressor](https://github.com/taylorbayouth/llm-text-compressor)
* [PCToolkit: A Unified Plug-and-Play Prompt Compression Toolkit of Large Language Models](https://github.com/3DAgentWorld/Toolkit-for-Prompt-Compression)
* [Selective Context for LLMs](https://github.com/liyucheng09/selective_context)
* [LLMLingua](https://github.com/microsoft/LLMLingua)

I''m not exactly sure where I'm going with this. I mainly wanted a vehicle for exploring an agentic workflow and building an intuition for how smart local LLMs can be.


## Instructions

Follow these instructions to run the file condenser.

1. Pre-requisite: `uv`
   * I'm using 0.7.7
2. Run the condenser
   * ```bash
     ./text-condenser.py text-condenser.py.lock
     ```
   * The tool will process the input file and output the condensed version.
3. Occasionally, recreate the dependencies lock file
   * ```bash
     uv lock --script text-condenser.py
     ```


## Example

Let's take a simple example of the _redundantly verbose -> condense_ transformation that we can do with `text-condenser`. [Nushell](https://github.com/nushell/nushell) prints structured data with ASCII table art. Let's look at the before and after, including token counts:

```text
$ ls | table | save -f ls.txt
$ open ls.txt
╭───┬────────────────────────┬──────┬─────────┬─────────────╮
│ # │          name          │ type │  size   │  modified   │
├───┼────────────────────────┼──────┼─────────┼─────────────┤
│ 0 │ README.md              │ file │  7.4 kB │ 2 hours ago │
│ 1 │ text-condenser.py      │ file │  3.7 kB │ 2 hours ago │
│ 2 │ text-condenser.py.lock │ file │ 15.0 kB │ 2 hours ago │
╰───┴────────────────────────┴──────┴─────────┴─────────────╯

$ open ls.txt | token-count
769

$ ./text-condenser.py ls.txt | save -f ls-condensed.txt
$ open ls-condensed.txt
0: README.md (file, 7.4 kB, 2 hours ago)
1: text-condenser.py (file, 3.7 kB, 2 hours ago)
2: text-condenser.py.lock (file, 15.0 kB, 2 hours ago)

$ open ls-condensed.txt | token-count
64

$ rm ls.txt; rm ls-condensed.txt
```

The condensed version preserves most of the information but reduces tokens by removing the characters making up the ASCII table art. 

* Before: 769 tokens
* After: 64 tokens
* Fractional size: **8.32%** of the original (this is an egregiously contrived example, but it shows the idea)

However, it's not perfect, we've actually lost the information about the column names: "name", "type", "size", "modified". It's a trade-off.


## Implementation Constraints

* I want this as only one Python file (`text-condenser.py`). Keep it reduced and avoid feature bloat.
* Minimal external dependencies. Rely on the LLM to do "smart" things
* Use `uv` and inline script metadata (PEP 723) 


## Design

The core algorithm works as follows:

1. **Chunked Reading** (NOT IMPLEMENTED): Files are processed 10 lines at a time to manage memory and allow for incremental processing
2. **Vocabulary Building** (NOT IMPLEMENTED): As the agent processes chunks, it builds a vocabulary of condensing strategies
3. **Backtracking** (NOT IMPLEMENTED): When new condensing opportunities are discovered, the agent can revisit earlier chunks to apply
   improved strategies
4. **Tool Calls** (NOT IMPLEMENTED): The agent uses defined tools for:
   - Reading file chunks
   - Writing condensed output
   - Managing vocabulary and state
   - Backtracking to previous chunks

The implementation is primarily prompt-driven, with the LLM doing the heavy lifting of understanding content and
applying condensing strategies. The Python code provides the orchestration loop and tool infrastructure.


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [x] DONE "Hello world" prompt using ollama Python bindings
* [x] DONE Implement one-shot condensing (full file)
* [ ] Pare down the implementation. AI sloppy.
* [ ] I want to see progress. I want to see the thinking tokens as they occur. Also the output jams the `<think>` content in the same output. What are my options for delimiting this?
* [ ] Defect. The condense on the lock file is missing the first few deps? Truncation?
* [ ] Wire in tool support. Start with "read next file" or something? I don't ever want the LLM to construct file *paths* for reading/writing. It needs to be constrained to allowed file paths. 
* [ ] Integration with token-count tool for before/after comparisons. This is a pre-requisite for chunked condensing.
* [ ] Implement chunked condensing (X tokens at a time). This is where the agent comes in?
* [x] DONE (decided on `text-condenser`) Consider renaming as "prompt compressor". This is a clearer name. I went with condenser for disambiguation and I went with "file" because I'm not trying to compress my prompts exactly, but the file attachments I put in my prompts.
* [ ] Consider condensing into a `.md` file with YAML front-matter, from which there can be structured data like keywords, etc. That way the condensed files can be searched/indexed with traditional tools. Even relationships. Better yet... maybe this should all just go into a SQLite db? Update: I like the keywords "dense" and "text".
* [ ] Consider evals.


## Reference

* [Qwen3-30B-A3B-FP8 on HuggingFace](https://huggingface.co/Qwen/Qwen3-30B-A3B-FP8)
* [PEP 723 – Inline script metadata](https://peps.python.org/pep-0723/)
