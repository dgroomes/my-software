# mcp-rules

**NOTICE**: This is an AI first draft. Needs evolution.

An MCP server for bootstrapping LLM agents with user and project-specific rules.


## Overview

The Rules MCP server solves a fundamental bootstrapping problem in LLM workflows: how to efficiently load context-specific instructions before an agent begins its work. Just as a README file commands readers to "read me first," this server ensures agents load their rules first.

This is a bootstrapping problem because the execution chain works backwards: an AI chat session relies on an MCP server config, which relies on installed tools, and those tools must load user-defined rules before providing useful advice or generating code. Without this bootstrap step, agents lack the context to work effectively.

The server exposes a single tool:
* `LoadRules()` - Locates and returns rule files from user, project, and user-project contexts

### The Problem Statement

When working with LLM agents like Cursor, Claude Code, or Copilot, users accumulate valuable patterns, preferences, and project-specific knowledge. This wisdom gets scattered across:
- Memory features (like Claude's CLAUDE.md)
- Cursor rules files
- Project-specific conventions
- Personal coding preferences

Each tool has its own mechanism, creating fragmentation. We need a unified way to bootstrap agents with this context.

### Prior Art and Inspiration

This project builds on established patterns:
- **CLAUDE.md** - Claude Code's memory feature that loads project context
- **Cursor rules** - Project-specific instructions for the Cursor editor
- **README files** - The universal "read me first" convention

The key insight is that these are all rules - instructions that guide agent behavior. By standardizing on a simple format (markdown files named `AGENT.md`), we create a portable solution.

### Why "AGENT.md"?

The filename `AGENT.md` was chosen for its clarity and brevity:
- **AGENT** - Makes it clear the audience is an AI agent (in today's context, this unambiguously means an LLM agent)
- **.md** - Indicates prose written in markdown, not structured data like JSON. The content has statistical structure (natural language patterns) rather than rigid schema

This short name is important because these files will appear frequently: at least one per project, one in the home directory, and potentially hidden versions in `.my/` directories.

### The ".my" Directory Convention

The `.my/` directory serves as a git-ignored, project-local space for personal customizations. This allows:
- User-specific rules that shouldn't be committed to version control
- Temporary context for current work sessions
- Personal preferences overlaid on team projects

### Rule File Locations

The Rules server searches for `AGENT.md` files in three contexts:

1. **User rules** - `~/.config/llm-agent/AGENT.md`
   - Global preferences and patterns
   - Shared across all projects
   
2. **Project rules** - `./AGENT.md` (in project root)
   - Team conventions and project standards
   - Committed to version control
   
3. **User-project rules** - `./.my/AGENT.md`
   - Personal overrides for the current project
   - Git-ignored, not shared with team

### Why XDG Base Directory?

For global rules, we use `~/.config/llm-agent/` following the XDG Base Directory specification. Why not macOS's `~/Library/Application Support`?
- Too verbose for CLI usage - users need to reference these paths
- Not portable to Linux systems
- Hidden from casual browsing

The `llm-agent` prefix is necessary in shared locations like `~/.config` because outside an LLM context, "agent" is ambiguous. The prefix clarifies we're dealing with LLM agent configuration.


## Instructions

Follow these instructions to build, test, and run the Rules MCP server:

1. Pre-requisite: Node.js
   * I'm using `v20.17.0`
2. Activate the Nushell `do` module
   * ```nushell
     do activate
     ```
3. Generate the `package.json` file (if needed)
   * ```nushell
     do package-json
     ```
4. Install dependencies
   * ```nushell
     do install
     ```
5. Build the server
   * ```nushell
     do build
     ```
6. Run the server with the MCP Inspector
   * ```nushell
     do run-with-inspector
     ```
7. Set up the server in your MCP-compatible editor
   * Add the following to your editor's MCP configuration:
     ```json
     {
       "mcp": {
         "servers": {
           "rules": {
             "command": "/path/to/mcp-rules.sh"
           }
         }
       }
     }
     ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [ ] Scaffold the TypeScript MCP server with a single `LoadRules` tool
* [ ] Implement rule file discovery logic for all three contexts (user, project, user-project)
* [ ] Handle missing files gracefully - return helpful messages instead of errors
* [ ] Add file watching to detect when rule files change
* [ ] Consider caching rules with appropriate invalidation
* [ ] Create example AGENT.md files showing effective rule patterns
* [ ] Add a tool for listing which rule files were found
* [ ] Consider supporting additional rule file locations (like workspace-specific rules)
* [ ] Document best practices for writing effective rules
* [ ] Add validation to ensure rules don't contain sensitive information
