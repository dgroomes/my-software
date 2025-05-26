# file-condenser

**WARNING**: This is an AI first draft. (It saved me time and effort, but needs corrections)

An LLM-powered tool that condenses files by removing redundant syntax while preserving information content.


## Overview

This tool uses the Qwen3 language model to intelligently condense files, particularly structured data files like JSON, by
removing redundant syntax elements (field names, brackets, punctuation) while preserving the actual information. Unlike
a summarizer that omits details or a compressor that preserves all bits, this "condenser" creates a lossy but
information-rich representation that's ideal for feeding into LLMs.

The primary use case is reducing token counts of files to fit within LLM context windows. LLMs excel at reading fuzzy,
natural language representations and don't require perfect syntax preservation. By condensing files this way, we can fit
more meaningful content into limited context windows.

This project leverages Qwen3's 30B model (8-bit quantized) which can run locally on a Mac with 32GB RAM. The model's
tool-calling capabilities enable an agentic approach where the program can intelligently chunk through files, build
vocabulary, and even backtrack to apply newly discovered condensing strategies to earlier content.


## Instructions

Follow these instructions to run the file condenser.

1. Pre-requisite: Python
   * I'm using Python `3.12.7` which is available on my PATH as `python3`.
2. Pre-requisite: uv
   * Install uv for managing Python dependencies inline.
3. Pre-requisite: GPU/Memory
   * Ensure you have sufficient memory to run Qwen3 30B quantized model (approximately 20-25GB RAM).
4. Run the condenser
   * ```bash
     python3 file-condenser.py input.json > output.txt
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

The condensed version preserves all the meaningful information but reduces tokens by ~70% through removing redundant
JSON syntax.


## Implementation Details

The file condenser is implemented as a single Python file using uv's inline script metadata (PEP 723) for dependency
management. The program uses HuggingFace's transformers library to load and run the Qwen3 model locally.

The core algorithm works as follows:

1. **Chunked Reading**: Files are processed 10 lines at a time to manage memory and allow for incremental processing
2. **Vocabulary Building**: As the agent processes chunks, it builds a vocabulary of condensing strategies
3. **Backtracking**: When new condensing opportunities are discovered, the agent can revisit earlier chunks to apply
   improved strategies
4. **Tool Calls**: The agent uses defined tools for:
   - Reading file chunks
   - Writing condensed output
   - Managing vocabulary and state
   - Backtracking to previous chunks

The implementation is primarily prompt-driven, with the LLM doing the heavy lifting of understanding content and
applying condensing strategies. The Python code provides the orchestration loop and tool infrastructure.

Dependencies are minimal:
- `transformers` - For loading and running Qwen3
- `torch` - Required by transformers
- Standard library modules for file I/O and orchestration


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [ ] Implement the basic chunked file reading loop
* [ ] Add Qwen3 model loading with appropriate quantization settings
* [ ] Design and implement the tool-calling interface for file operations
* [ ] Create comprehensive prompts for the condensing task
* [ ] Add vocabulary persistence between chunks
* [ ] Implement the backtracking mechanism for applying new strategies
* [ ] Add support for different file types (JSON, YAML, TOML, etc.)
* [ ] Create benchmarks showing token reduction percentages
* [ ] Add a dry-run mode that estimates token savings without full processing
* [ ] Support for custom condensing strategies via configuration
* [ ] Batch processing mode for multiple files
* [ ] Integration with token-count tool for before/after comparisons


## Reference

* [Qwen/Qwen2.5-32B-Instruct on HuggingFace](https://huggingface.co/Qwen/Qwen2.5-32B-Instruct)
* [PEP 723 – Inline script metadata](https://peps.python.org/pep-0723/)
* [HuggingFace Transformers documentation](https://huggingface.co/docs/transformers)
* [Guidance - A guidance language for controlling large language models](https://github.com/guidance-ai/guidance)
