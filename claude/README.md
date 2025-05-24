# claude

My personal config for Claude Code.


## Memory

I'm on a learning journey with Claude Code, including its [memory](https://docs.anthropic.com/en/docs/claude-code/memory) feature.

I'm trying to keep the instructions short and make sure I get the syntax right for imports, but a lot of this is based on vibes.

I'm having success with Git working trees and a `.my/` git-ignored directory for building up context for the LLM to use.

A problem I'm running into is with imports and relative paths. It might feel effective to express an instruction in the user (global) `~/.claude/CLAUDE.md` file that has an import like this:

```md
* Study @.my/CLAUDE.md if it exists for additional context.
```

But because the user Claude file is at `~/.claude`, then Claude Code will look for `@.my/CLAUDE.md` relative to that directory, which is `~/.claude/.my/CLAUDE.md` and of course that file does not exist because the `.my/` convention is about colocating files in the current working directory.

A workaround is to not use the `@`/auto-import feature and instead just ask Claude to read the file. It should be very good at doing that. I'm going to have to remember not to be too clever with the `CLAUDE.md` files in general.

Actually, it might be that `.my` is git-ignored or it might be that it is a "hidden" file due to the leading `.`. It looks like there are user frustrations about this when I look at Claude Code discussions online.

Ok this is a bit obnoxious, Claude is not consistently reading the `CLAUDE.md` project file and there's even less of a way to make it read the `.my/CLAUDE.md` file. What if I eject from this mechanism and instead make an MCP server called "agent-start-here" or something and that way I can programmatically read and return `.my/README.md` and maybe even more context. That way it's also not tied to `CLAUDE` and is a bit more portable for any MCP-compatible LLM.
