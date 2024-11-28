# javascript

JavaScript code that supports my personal workflows.


## Instructions

1. Pre-requisite: Node.js
   * I'm using `v20.17.0`
2. Activate the Nushell `do` commands
   * ```nushell
     do activate
     ```
3. Install dependencies
   * ```nushell
     do install
     ```
4. Build and run the program
   * ```nushell
     do build; do run 
     ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [ ] Bring back the markdown linter code/config I had and make a JS launcher. This means extending my Go-based
  launcher.
* [x] DONE Scaffold.
* [ ] Create "json-validator" program (its own distributable?) that communicates via clients on Unix domain socket.
* [ ] Consider splitting into independent subprojects. npm workspaces aren't quite there and I want to isolate the
  incidental (large) complexity like webpack from one project to the next. 
* [ ] Do something interesting with AJV.
