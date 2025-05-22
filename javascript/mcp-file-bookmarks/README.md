# mcp-file-bookmarks

An MCP server for quickly referencing bookmarked local files.


## Overview

The File Bookmarks MCP server is designed to make it faster to reference frequently needed files for your LLM sessions.

The server exposes a curated list of *bookmarks* which are paths to files. The server has these tools:

* `howto()`
  * Teach the agent workflows about how to use the tools
* `list()`
  * List bookmarks and their descriptions
* `get(base_path: string, entry_path: string)`
  * Get the file contents of a bookmark

The vision is that you're in an agentic AI chat session, and you need to reference some content you've read a hundred times but can never remember, like a particular Bash snippet. Let's say you had previously bookmarked a Bash script and used a description that makes it clear that the script contains the snippet. Then, you can make the agent locate the bookmark file and pull in its contents into the chat session with a prompt like this:

* > !fb bash trick for curr dir

Because of the magic of LLMs, the agent can make sense of what you want.

`!fb` is short for "File Bookmarks" and it makes it clear to the agent that you are trying to read bookmarked files. I'm using `!` as an identifying shorthand because `#` I think is overloaded in existing tooling, but we'll see.


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
4. Build the server
   * ```nushell
     do build
     ```
5. Start the server with the MCP Inspector
   * ```nushell
     do run-with-inspector
     ```
6. Set up the server in VS Code
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

Bookmarks are stored in a `~/.local/file-bookmarks.json` file. I don't know how all this will shape up, so I'm just using a simple "directories of entries" approach now and manually editing the JSON file. Here is an example:

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


## Miscellaneous

* I want to use the STDIO transport NOT HTTP.
* I want all my ts code in one file. Right now, there are two files. Consolidate them.
* I don't want to bring in any extra dependencies besides the MCP TS SDK, if possible.
* I want to convey errors in a way that's idiomatic with MCP protocol. Concise and useful error handling is hard. No need to throw an error and crash the program if it is recoverable.
* All code should be in one `.ts` file. This is a small project. Let's keep it simple.


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [x] DONE Triage code down to basic "hello world"-style server.
* [x] DONE Implement.
    * DONE Ok it's pretty good, but still AI sloppy. I need to attach examples from the MCP TS SDK.
    * DONE Consider error handling. Is it idiomatic compared to the example TS servers? Are we propagating the "MCP way"?
    * DONE Is this Zod stuff even right? Are the types of the tool calls expressed correctly?
    * DONE Take another pass over the code. There are multiple differences from the vision in the README. For one, I need to implement the `howto()` tool. I also need to make sure I'm handling the multiple match and none match cases correctly. These are all just instructions for the agent from the `howto()` tool.
    * DONE (Yes, wow nice. LLMs can sometimes follow instructions amazingly) Does it work?
* [x] DONE Revive the vision of the project and encode it in the overview and wish list. Some of the original AI slop tech debt is asking for its interest payment: it's hard to know if a sentence was original (useful) or AI generated (a chance of being irrelevant and wasting my time).
* [x] DONE Consider being very narrow on the scope. I like the keywords "bookmarks", "local", "files", "library", "context", and "reference". I'm not sure what I like most. But I need to keep this simple enough to be useful.
* [ ] My functions should use MCP response types instead of strings. I need to be able to return the `isError: true` when needed.
* [ ] Keep track of 'howto'. Return an error if other tools are called before `howto()`.