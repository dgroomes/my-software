# python

Python code that supports my personal workflows.


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
      open README.md | poetry run python -m my_software.token_count
      ```
    * It will print the number of tokens in the README.md file.
5. Build a wheel distribution
   * ```nushell
     poetry build
     ```
6. Install the wheel distribution
   * ```nushell
     glob dist/*.whl | get 0 | pipx install --python python3.12 $in
     ```
   * It should look something like the following.
   * ```text
     $ glob dist/*.whl | get 0 | pipx install --python python3.12 $in
       installed package my_software 0.1.0, installed using Python 3.12.7
       These apps are now globally available
         - token-count
     done! ✨ 🌟 ✨
     ```


## Reference

* [My own GitHub repository: `poetry-playground`](https://github.com/dgroomes/python-playground)
