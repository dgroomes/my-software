# llm-agent

My personal rules for LLM agents like Claude Code, GitHub Copilot, etc.

I'm still learning what is effective. I'm trying to keep things short, especially because that's the constant advice from people at Anthropic, etc. It's a balance between simple (quint but probably effective) and complex (ambitious but probably inconsistently followed).


## Auto-loading Strategy

I'm using my Rules MCP server to auto-load my rules. This takes some bootstrapping gymnastics to convince the agents to actually load the rules.

We'll express a "START_HERE and load the rules via the MCP tool" instruction in each of the vendor-specific rules locations. This stinks a bit because we're cluttering the home directory with these files and paying the cost of maintenance, but this will have to do. One day there will likely be standardization.

For Claude, we'll maintain a global `~/.claude/CLAUDE.md` file with the instruction.

For GitHub Copilot in VS Code, it's a bit more complicated. You have to use special front-matter in the markdown file to indicate that the instructions should apply to all files, you have to name the file ending with `.instructions.md`, and there isn't a default global location for rules.

VS Code does have an experimental setting for additional rules locations. See the `vscode/settings.json` file for details. I've really struggled to come up with a sane place for this. I don't really want to make up an "official looking" directory, like `~/.github` and `~/.github/instructions` because that might embed a misconception into my long term memory, thinking that's somehow an official directory. (I keep thinking it is but it's empty. I don't even know where `gh` keeps data, if anywhere). To reduce the pollution in the home directory, I'll go with `~/.config/llm-agent/COPILOT_START_HERE.instructions.md` for now.
