# mcp-rules

An MCP server for bootstrapping LLM agents with user and project-specific rules.


## Overview

The Rules MCP server implements a fundamental step in LLM workflows: loading context-specific instructions before an agent begins its work. Just as a README file commands readers to "read me first," this server ensures agents load their rules first.

The server exposes a single tool:
* `load_rules()` - Locates and returns agent rules. Searches the conventional _user_, _project_, and _user-project_ locations.


## The Problem: Competing Conventions

When working with LLM agents, users accumulate valuable instructions for the agent about architecture, code style, and more. But, these rules are scattered across many locations:

* Cursor uses `.cursor/rules/{rule_name}.mdc`
* Copilot uses `.github/copilot-instructions.md`
* Windsurf uses `.windsurf/rules/{rule_name}.md`
* Claude Code uses `CLAUDE.md`
* OpenAI's Codex CLI uses `AGENTS.md`

How does an agent know which rules to load? Should the agent load all of them?


## `AGENT.md`

Emboldened by the "fast software writing and maintenance" I get from LLMs and the standardization we have with the Model Context Protocol, I'm going to solve this problem for myself by creating my own convention and related tooling: the `AGENT.md` file and the Rules MCP server.

Why the name `AGENT.md`?

* It's short: A single word and short extension.
* It's familiar: While "agent" means many things broadly, in the context of reading and writing code, we often know it to mean an AI/LLM agent.
* Precedent: OpenAI's Codex CLI uses `AGENTS.md`, so `AGENT.md` (singular) is a natural variation


## The `.my/` Directory

I often create `.my/` directories in my projects to help me work on my current task. I globally git-ignore this directory. I use it for:

* LLM prompts
* Storing reference files to be used as LLM context
* Stashing LLM outputs or old code for reference if I need to undo some work

The Rules server looks in the `.my/` directory for an `AGENT.md` file. This is a form of *user-project rules* because they are user-defined but specific to the current project.


### Rule File Locations

The Rules server searches for `AGENT.md` files in three contexts:

1. **User rules** - `${XDG_CONFIG_HOME}/llm-agent/AGENT.md`
   * User-specified rules that should apply to all projects
   * These rules often encode personal workflow/chat preferences like "Always commit after writing code"
2. **Project rules** - `./AGENT.md` (in current directory and upwards)
   * Project-specific rules that are agreed upon and shared by the team
   * Committed to version control
3. **User-project rules** - `./.my/AGENT.md`
   - Personal overrides and additions for the current project
   - Git-ignored, not shared with team

I wrestled with using just `~/.AGENT.md` for user rules, but I don't want to clutter the home directory, and the word "agent" in that context is not necessarily obviously related to LLMs. So, I chose `${XDG_CONFIG_HOME}/llm-agent/AGENT.md` to keep it explicitly named and isolated.


## Instructions

Follow these instructions to build, test, and run the Rules MCP server:

1. Install dependencies
   * ```nushell
     npm install
     ```
2. Build the server
   * ```nushell
     npx tsc
     ```
3. Run the server with the MCP Inspector
   * ```nushell
     npx @modelcontextprotocol/inspector@0.9.0 ./rules.sh
     ```
4. Set up the server in your MCP-compatible editor
   * Add the following to your editor's MCP configuration:
     ```json
     {
       "mcp": {
         "servers": {
           "rules": {
             "command": "/path/to/rules.sh"
           }
         }
       }
     }
     ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [ ] Implement
* [ ] Consider using an identifying string like `!rules` and supporting skipping rules loading like with a user message "!rules skip"
  or listing rules location files with `!rules locations`. Not sure yet.
