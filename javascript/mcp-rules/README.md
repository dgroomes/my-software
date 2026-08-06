# mcp-rules

An MCP server for bootstrapping LLM agents with user-global and user-local rules.


## Overview

The Rules MCP server implements a fundamental step in LLM workflows: loading context-specific instructions before an agent begins its work. Just as a README file commands readers to "read me first," this server ensures agents load their rules first. (I think "instructions" makes more sense than "rules", but for brevity and to be consistent with common convention I'll stick to "rules").

The server exposes a single tool:
- `load_rules()` - Locates and returns agent rules. Searches the conventional _user-global_ and _user-local_ locations.


## The Problem: Competing Conventions

When working with LLM agents, users accumulate useful rules for the agent about the project's architecture, code style, and more. But, these rules are scattered across different vendor locations. Confusingly, the tools often cross into the conventions of another vendor (e.g. `CLAUDE.md`):

<table>
  <thead>
    <tr>
      <th></th>
      <th>User Rules</th>
      <th>Project Rules</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Claude Code</td>
      <td>
        <ul>
          <li><code>~/.claude/CLAUDE.md</code></li>
          <li><code>~/.claude/rules/*.md</code></li>
        </ul>
      </td>
      <td>
        <ul>
          <li><code>CLAUDE.md</code></li>
          <li><code>.claude/CLAUDE.md</code></li>
          <li><code>.claude/rules/*.md</code></li>
          <li><code>CLAUDE.local.md</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td>Codex</td>
      <td>
        <ul>
          <li><code>~/.codex/AGENTS.md</code></li>
        </ul>
      </td>
      <td>
        <ul>
          <li><code>AGENTS.md</code></li>
          <li><code>AGENTS.override.md</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td>GitHub Copilot</td>
      <td>
        <ul>
          <li><code>~/.copilot/copilot-instructions.md</code></li>
          <li><code>~/.copilot/instructions/**/*.instructions.md</code></li>
          <li><code>~/.claude/CLAUDE.md</code> (VS Code)</li>
        </ul>
      </td>
      <td>
        <ul>
          <li><code>.github/copilot-instructions.md</code></li>
          <li><code>.github/instructions/**/*.instructions.md</code></li>
          <li><code>AGENTS.md</code></li>
          <li><code>CLAUDE.md</code></li>
        </ul>
      </td>
    </tr>
    <tr>
      <td>Cursor</td>
      <td>
        <ul>
          <li>User rules defined in Cursor Settings</li>
        </ul>
      </td>
      <td>
        <ul>
          <li><code>.cursor/rules/*.mdc</code></li>
          <li><code>AGENTS.md</code></li>
          <li><code>CLAUDE.md</code></li>
        </ul>
      </td>
    </tr>
  </tbody>
</table>


How does an agent know which rules to load? Should the agent load all of them?


## My Solution: Expanded Search and Standardization of AGENTS.md

Emboldened by the "fast software writing and maintenance" power I get from LLMs and the standardization we have with the Model Context Protocol, I'm going to solve this problem for myself by creating my own convention and related tooling: standardize on the `AGENTS.md` file and expand its scope to be in both a user-global location (`~/.config/llm-agent/AGENTS.md`) and user-local locations (`.my/AGENTS.md`).


## The `.my/` Directory

I often create `.my/` directories in my projects to help me work on my current task. I globally git-ignore this directory. I use it for:

- Agent plans/prompts for my current task  
- Project-specific rules
- Project-specific shell scripts
- Reference repos (I `git clone ...` in `.my/repos/`)
- Scratch location for data and experiments 

The Rules server looks in the `.my/` directory for an `AGENTS.md` file. This is a form of *user-local* rules because they are user-defined and specific to the current project.


### Rule File Locations

The Rules server searches for `AGENTS.md` files in two contexts:

1. User-global rules: `~/.config/llm-agent/AGENTS.md`
   - User-specified rules that should apply to all projects
   - These rules often encode personal workflow/chat preferences like "Always commit after writing code"
2. User-local rules: `./.my/AGENTS.md`
   - Personal overrides and additions for the current project
   - Git-ignored, not shared with team

I wrestled with using just `~/AGENTS.md` for user-global rules, but I don't want to clutter the home directory, and the word "agent" in that context is not necessarily obviously related to LLMs. So, I chose `~/.config/llm-agent/AGENTS.md` to keep it explicitly named and isolated.


## Instructions

Follow these instructions to build, test, and run the Rules MCP server:

1. Activate the Nushell `do` module
   - ```nushell
     do activate
     ```
2. Generate the `package.json` file (if needed)
   - ```nushell
     do package-json
     ```
3. Install dependencies
   - ```nushell
     do install
     ```
4. Build the server
   - ```nushell
     do build
     ```
5. Start the server with the MCP Inspector
   - ```nushell
     do run-with-inspector
     ```
6. Set up the server in your MCP-compatible editor
   - Add the following to your editor's MCP configuration:
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
   - Or use one of these commands to install into Claude or Codex.
   - ```nushell
     do install-to-claude
     ```
   - ```nushell
     do install-to-codex
     ```
7. You might want to add "mcp__rules__load_rules" to the "permissions.allow" array field in your `~/.claude/settings.json` file to always allow usage (less friction).


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

- [ ] OBSOLETE (already done with '!rules off' in the prompt) Consider using an identifying string like `!rules` and supporting skipping rules loading like with a user message "!rules off"
  or listing rules location files with `!rules locations`. Not sure yet.
- [ ] SKIP (skip; keep it simple) Consider `.mdc` extension and/or using the standard header metadata for things like the path of the rule file and importance level. Not sure it matters.
- [x] DONE Consider going to AGENTS.md. I think it would be rude to version control an AGENT.md (singular) file because no one else uses this convention (well, I would only ever do that on a personal repo) 
- [x] DONE Stop loading "project" rules. While it is a noble goal, in practice, I just really need a solution for common global rules, and project-user rules. And each of the vendor tools are pretty good about loading CLAUDE.md and AGENTS.md and that's what is likely already version controlled in a repo.
- [ ] Upgrade to MCP inspector 2.0. I tried it but it isn't interacting with the rules MCP server properly. When invoking "load_rules", the UI spins.
- [x] DONE Consider calling it "user global" for clarity, to contrast with "user project" (or even name that "user local").
- [ ] Make it clear that I've only implemented global and local "launch" dir rule loading, not a mechanism for loading rules as the agent moves around dirs. That's a job for the agent to do and thankfully there's decent standardization on AGENTS.md, and also I don't often use that feature.
