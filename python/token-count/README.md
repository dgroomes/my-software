# token-count

A utility for estimating token counts in text using OpenAI's tiktoken library.


## Overview

This tool reads text from standard input and outputs an estimated token count. It's useful for understanding the size
of prompts and responses when working with LLMs. The tool uses OpenAI's "o200k_base" tokenizer (used by GPT-4o) as a
reasonable approximation for various models.


## Instructions

Follow these instructions to build and run the code.

1. Pre-requisite: Poetry
    * I'm using Poetry `1.8.4` which I installed via `pipx`.
2. Pre-requisite: Python
    * I'm using Python `3.12.7` which is available on my PATH as `python3` and `python3.12`.
3. Install dependencies
    * ```nushell
      poetry install
      ```
4. Run a token count
    * ```nushell
      open README.md | poetry run python -m token_count.token_count
      ```
    * It will print the number of tokens in the README.md file.
5. Build a wheel distribution
    * ```nushell
      poetry build
      ```
6. Install the wheel distribution
    * ```nushell
      glob dist/*.whl | first | pipx install --python python3.12 $in
      ```
    * It should look something like the following.
    * ```text
      $ glob dist/*.whl | get 0 | pipx install --python python3.12 $in
        installed package my_software 0.1.0, installed using Python 3.12.7
        These apps are now globally available
          - token-count
      done! ✨ 🌟 ✨
      ```
