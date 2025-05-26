# file-condenser

**WARNING**: This is an AI first draft. (It saved me time and effort, but needs corrections)

An LLM-powered tool that condenses files by removing redundant syntax while preserving information content.


## Overview

This tool uses a local LLM to intelligently condense files, particularly structured data files like JSON, by
removing redundant syntax elements (field names, brackets, punctuation) while preserving the actual information. Unlike
a _summarizer_ that omits details or a _compressor_ that preserves all bits, this _condenser_ creates a lossy but
information-rich representation that's ideal for feeding into LLMs.

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

1. Pre-requisite: Python
   * I'm using Python `3.13.3` which is available on my PATH as `python3`.
2. Pre-requisite: `uv`
   * I'm using 0.7.7
3. Run the condenser
   * ```bash
     uv file-condenser.py input.json > output.txt
     ```
   * The tool will process the input file in chunks and output the condensed version.


## Example

Given a `package.json` file like:
```json
{
  "name": "my-project",
  "version": "1.0.0",
  "description": "A sample Node.js project",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "test": "jest",
    "build": "webpack"
  },
  "dependencies": {
    "express": "^4.18.0",
    "lodash": "^4.17.21"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "webpack": "^5.74.0"
  }
}
```

The condenser might output:
```
my-project v1.0.0 - sample Node.js project
entry: index.js
commands: start=node index.js, test=jest, build=webpack
deps: express 4.18.0, lodash 4.17.21
dev: jest 29.0.0, webpack 5.74.0
```

The condensed version preserves most of the meaningful information but reduces tokens by removing redundant JSON syntax.


## Implementation Constraints

* I want this as only one Python file (`file-condenser.py`). Keep it reduced and avoid feature bloat.
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

* [ ] IN PROGRESS "Hello world" prompt using ollama Python bindings
* [ ] Implement one-shot condensing (full file)
* [ ] Wire in tool support. Start with "read next file" or something? I don't ever want the LLM to construct file *paths* for reading/writing. It needs to be constrained to allowed file paths. 
* [ ] Integration with token-count tool for before/after comparisons. This is a pre-requisite for chunked condensing.
* [ ] Implement chunked condensing (X tokens at a time). This is where the agent comes in?
* [ ] Consider renaming as "prompt compressor". This is a clearer name. I went with condenser for disambiguation and I went with "file" because I'm not trying to compress my prompts exactly, but the file attachments I put in my prompts. Also, I want to consider condensing into a `.md` file with YAML front-matter, from which there can be structured data like keywords, etc. That way the condensed files can be searched/indexed with traditional tools. Even relationships. Better yet... maybe this should all just go into a SQLite db?
* [ ] Consider evals.


## Reference

* [Qwen3-30B-A3B-FP8 on HuggingFace](https://huggingface.co/Qwen/Qwen3-30B-A3B-FP8)
* [PEP 723 – Inline script metadata](https://peps.python.org/pep-0723/)
* [HuggingFace Transformers documentation](https://huggingface.co/docs/transformers)
* [Guidance - A guidance language for controlling large language models](https://github.com/guidance-ai/guidance)
