# nushell-ast-printer

A program that prints the AST of a Nushell snippet as JSON.


## Instructions

Follow these instructions to build and run the code.

1. Activate the `do` Nushell scripts
   * ```nushell
     do activate
     ```
2. Build and run the `nushell-ast-printer` program
   * ```nushell
     'echo "hello there" world' | do run
     ```
3. Install the program
   * ```nushell
     do install
     ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project

* [x] DONE output JSON
* [ ] SKIP (I think I got what I needed? The heavy lifting logic has to go in the Go program) tests
