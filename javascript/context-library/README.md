# mcp-context-library NOT YET IMPLEMENTED (AI slop/gold)

An MCP server that provides quick access to reference files and directories from local git repositories.


## Overview

The MCP Context Library server offers fast access to frequently referenced files and directories in your local git repositories. This tool is designed to solve the common problem of needing to reference specific files during development work, whether they're configuration examples, important documentation, or code snippets.

The server maintains a curated list of "library entries" - paths to files or directories that you've found particularly useful. These entries are stored in a simple JSON file that grows over time as you add more references.

When used with Claude in VS Code, this tool allows you to:
- Browse your library entries directly in chat
- Instantly fetch and view the contents of reference files
- Access frequently used configuration examples and templates
- Study important parts of codebases without switching contexts

The goal is to reduce friction when referencing important files, helping you maintain focus during development tasks.


## Instructions

Follow these instructions to build, test, and run the MCP Context Library server:

1. Activate the Nushell `do` module
   * ```shell
     do activate
     ```
2. Generate the `package.json` file (if needed)
   * ```shell
     do package-json
     ```
3. Install dependencies
   * ```shell
     do install
     ```
4. Run tests
   * ```shell
     do test
     ```
5. Build the server
   * ```shell
     do build
     ```
6. Run the server in interactive mode for testing
   * ```shell
     do run
     ```
7. Set up the server in VS Code
   * Add the following to your VS Code settings.json file:
     ```json
     {
       "mcp": {
         "servers": {
           "context-library": {
             "command": "/path/to/context-library.sh"
           }
         }
       }
     }
     ```


## Using the Server

The server provides the following tools:

### list_entries

Lists all available library entries, optionally filtering by a pattern.

Parameters:
- `pattern` (optional): A glob pattern to filter entries (e.g., "*.md" or "java/**")
- `exclude_patterns` (optional): An array of glob patterns to exclude (e.g., ["**/node_modules/**", "**/*.log"])

Example:
```
$ list_entries
```

Output:
```json
{
  "entries": [
    {
      "path": "go/README.md",
      "description": "Documentation for Go utilities"
    },
    {
      "path": "javascript/json-validator/README.md",
      "description": "JSON validator documentation"
    },
    ...
  ]
}
```

### fetch_entry

Fetches the content of a specific library entry.

Parameters:
- `path`: The path of the entry to fetch

Example:
```
$ fetch_entry { "path": "go/README.md" }
```

Output:
```
# go

Go code that supports my personal workflows.

...
```

## Library Entries

Library entries are stored in a JSON file with the following structure:

```json
{
  "base_path": "~/repos/personal/my-software",
  "entries": [
    {
      "path": "go/README.md",
      "description": "Documentation for Go utilities"
    },
    {
      "path": "javascript/json-validator/README.md",
      "description": "JSON validator documentation"
    }
  ]
}
```

You can edit this file manually to add, remove, or modify entries.

## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [ ] Add support for multiple base paths
* [ ] Implement automatic discovery of interesting files
* [ ] Add a tool to add new entries directly from Claude
* [ ] Support version control awareness (e.g., fetch different versions of files)
* [ ] Add support for rich content rendering (e.g., Markdown, code with syntax highlighting)
