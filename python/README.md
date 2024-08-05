# python

My Python personal software.


## Instructions

Follow these instructions to build and run the code.

1. Pre-requisite: Poetry
    * I'm using Poetry `1.8.3` which I installed via `pipx`.
2. Pre-requisite: Python
    * I'm using Python `3.12.4` which is available on my PATH as `python3` and `python3.12`.
3. Create a virtual environment
    * ```shell
      poetry env use python3.12
      ```
    * This will create a virtual environment tied to the Python interpreter pointed to by `python3.12` executable (or
      symlink) in a global cache directory that Poetry manages. Use the following command to see details about the
      virtual environment you just created.
4. Run a token count
    * ```shell
      cat README.md | poetry run python -m my_software.token_count
      ```
    * It will print the number of tokens in the README.md file.
5. Build a wheel distribution
   * ```shell
     poetry build
     ```
6. Install the wheel distribution
   * ```shell
     glob dist/*.whl | get 0 | pipx install $in
     ```
   * It should look something like the following.
   * ```text
     $ glob dist/*.whl | get 0 | pipx install $in 
       installed package my_software 0.1.0, installed using Python 3.12.4
       These apps are now globally available
         - token-count
     ```


## Reference

* [My own GitHub repository: `poetry-playground`](https://github.com/dgroomes/python-playground)
