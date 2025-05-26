# python

Python code that supports my personal workflows.


## Overview

This directory contains Python-based utilities and tools organized into subdirectories, each representing an independent
project with its own dependencies and configuration.


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [ ] Consider compacting. The `token_count:token_count:token_count` administration is too verbose, for example. Can we
  compress this? Is UV good for this? Single file programs with the metadata in the block comment at the top? I don't
  have a need for shared Python code right now and I'm not sure Python monorepo tooling is good at this point. Stick to
  individual projects.
* [ ] IN PROGRESS What can I get done with Qwen3?

--- IN PROGRESS ---

Let's work on the IN PROGRESS goal. I want you to bootstrap a high quality `README.md` for a Python subproject that uses Qwen3. Here is what I'm thinking.

Small local models like Gemma 3 are making waves. Event the quantized models are powerful (I think I can run the 30b 8-bit quant on my mac?). And Qwen3 has tool support. I want to create a toy agent implementation that's at least mildly interesting and practical. I've been thinking for a while about a "file describer" program that incrementally chunks a file and writes a compressed version of it.

* **It's not a summarizer**, but similar. A summarize omits lots of details. I actually want it to preserve LOTS of detail.
* **It's not a compressor**, but similar. Text compression algorithm usually preserve ALL bits. I want lossiness. I want to omit noise and keep signal.

Let's call it a "condenser".

Fro example, I'm interested in it taking like a long JSON file (package.json?) and rewriting the information but without the redundant field names, curly braces, etc. In this case I want to keep all the actual *information* but turn the document into fewer bytes. I don't care about preserving the format. I don't care about perfectly capturing every bit if info. This type of condensed information is perfect for feeding into LLMs because they don't trip up on reading syntax. They can handle fuzziness.That's the use-case I have, is reducing the token count of my files so that I can feed them into the LLM so they can fit into the context window.

Doing doing this condensing works is also perfect for LLMs because they are excellent at summarization.

* DO make a sibling of `token-count` in a dir call `file-condenser`.
* ONLY make the README.md for now. We will write the code later.
* DO make a README
* You can study `token-count` but there won't be much there to replicate except for the exact style of the README.
* DO study other readmes in my-software to understand the style I like and the volume of info I like. In particular, capture the one-liner, "Overview", "Instructions" and "Wish List" format I use
* DO catprue and summarize all the information and vision I've given here into the README. It should be self-contained.
* DO describe the problems statement, the opportunity and good fit for LLMs/agents (and local models?)
* DO expand on my vision and try to make an example of a file to be condensed and what the output might look like.

While  you are just writing the README and not doing the code, capture these details in the README about the implementation:

* DO NOT use Nushell. I think this project will only be two files? README and Python script.
* The agent will take a file, chunk read 10 lines at a time, keep track of what lines were read in some structured data (local variables?), then chunk forward and write output. The trick is that the agent can choose to BACKTRACK if it has found new information that it can use to better condense earlier lines. Kind of like a vocabulary works. If we find a new word useful for the vocabulary, we can go back and use it.
* The program should define tool calls for reading chunks from the file and whatever else to facilitate the work.
* I want to use HuggingFace's transformers lib
* I want to use a single file Python program with `uv`, using the "dependencies in the block comment" style.
* I DO NOT want to use any more dependencies than necessary
* The implemntation will be largey prompting. The LLM is going to do most of the work. We need to lots of prompt engineering to get it to do what we want. Our loop and logic will be pretty small.

Additional context files in this `.my/` directory...

* there is a copy of a conversation I had with chatgpt in `.my/conversation.md` about qwen and what I want to accomplish with it. Study it for extra specific information and guide your implementation.
* there is a copy of Python docs on "Inline script metadata" in `.my/incline-script-metadata.md`. Read this to understand how I want to write the program as a single-file with deps.


## Reference

* [My own GitHub repository: `poetry-playground`](https://github.com/dgroomes/python-playground)
