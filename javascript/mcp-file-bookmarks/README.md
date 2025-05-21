# mcp-file-bookmarks NOT YET IMPLEMENTED (AI slop/gold)

An MCP server for quickly referencing bookmarked local files.


## Overview

The File Bookmarks MCP server is designed to make it faster to reference frequently needed files in your LLM session.

The server uses a curated list of *bookmarks* which are paths to directories and files. These entries are stored in a simple JSON file. I don't know exactly how this will shape up. For now, I'm going to just maintain the entries by hand.

The vision of the usage is that you're in an AI chat session in an MCP host (e.g. VS Code, Claude Code) and you need to reference some content you've read a hundred times but can never remember, like a particular Bash snippet. You should be able to prompt it with things like this:

* > !fbg bash get curr dir abs path
* > !fbl my-software

The `!fbg` is short for "file bookmarks get" and it expresses that you want to get the contents of the bookmarked file that is identifiable by the hints you provided. The LLM cross-references that request with the known bookmarks and their descriptions and then asks the server to read the content of the file.

The `!fbl` is short for "file bookmarks list" and it expresses that you just want to list the bookmarks that match the hints you provided. Similarly, the LLM does the cross-referencing and then lists the matches in the chat session.

I'm using `!` as an identifying shorthand because `#` I think is overloaded in existing tooling, but we'll see.


## Instructions

Follow these instructions to build, test, and run the File Bookmarks MCP server:

1. Activate the Nushell `do` module
   * ```nushell
     do activate
     ```
2. Generate the `package.json` file (if needed)
   * ```nushell
     do package-json
     ```
3. Install dependencies
   * ```nushell
     do install
     ```
4. Run tests
   * ```nushell
     do test
     ```
5. Build the server
   * ```nushell
     do build
     ```
6. Run the server in interactive mode for testing
   * ```nushell
     do run
     ```
7. Set up the server in VS Code
   * Add the following to your VS Code settings.json file:
     ```json
     {
       "mcp": {
         "servers": {
           "file-bookmarks": {
             "command": "/path/to/file-bookmarks.sh"
           }
         }
       }
     }
     ```


## Bookmarks

Bookmarks are stored as an array in a `~/.local/file-bookmarks.json` file with the following structure:

```json
[
  {
    "base_path": "~/repos/personal/my-software",
    "description": "My personal software projects",
    "entries": [
      {
        "path": "go/README.md",
        "description": "Documentation for Go utilities"
      },
      {
        "path": "javascript/json-validator/README.md",
        "description": "JSON validator documentation"
      },
      {
        "path": "mcp/time/time.sh",
        "description": "Among other things, contains a 'Bash trick for getting current dir'"
      }
    ]
  },
  {
    "base_path": "~/repos/opensource/iceberg",
    "description": "Apache Iceberg",
    "entries": [
      {
        "path": "docs/docs/api.md",
        "description": "A brief overview of the API"
      }
    ]
  }
]
```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [ ] Triage code down to basic "hello world"-style server.
* [ ] Implement.
* [x] DONE Revive the vision of the project and encode it in the overview and wish list. Some of the original AI slop tech debt is asking for its interest payment: it's hard to know if a sentence was original (useful) or AI generated (a chance of being irrelevant and wasting my time).
* [x] DONE Consider being very narrow on the scope. I like the keywords "bookmarks", "local", "files", "library", "context", and "reference". I'm not sure what I like most. But I need to keep this simple enough to be useful.