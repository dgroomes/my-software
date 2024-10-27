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
   * It will output the following AST representation in JSON.
   * ```json
     {
       "type": "Block",
       "children": [
         {
           "type": "Call",
           "children": [
             {
               "type": "Name",
               "value": "print"
             },
             {
               "type": "String",
               "value": "\"Hello there, \""
             },
             {
               "type": "Variable",
               "value": "$person"
             }
           ]
         }
       ]
     }
     ```
3. Install the program
   * ```nushell
     do install
     ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project

* [x] DONE output JSON
* [ ] SKIP (I think I got what I needed? The heavy lifting logic has to go in the Go program) tests
* [x] DONE Use the "new-nu-parser" which is not yet fully developed but should be much easier to use. The regular Nu parser
  co-mingles scanning/parsing/binding/IR and I'm struggling to just get a simple AST.
   * "new-nu-parser" is not released on crates.io yet so we can do a relative path dependency in the Cargo.toml.
   * DONE (The vast majority is done, thanks Claude) Implement
   * DONE (Ok enough) Clean up


## Reference

* <https://github.com/nushell/new-nu-parser>
  * The new parser is designed to do lexing, resolving, and type checking in separate stages.
  * > In the old parser, all these stages were intertwined
