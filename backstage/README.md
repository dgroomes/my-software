# backstage

This is the "backstage": extra README content, repository TODO lists, and more.


## Overview

A root `README.md` is precious real estate. More broadly, the page content when viewing a repository on GitHub is precious real estate, and the `README.md` is a part of that. It's my preference to maximize the impact of the root README.

Annoyingly, the "above the fold" content is always the 5+ rows of fixed GitHub content and then the files and directories in the root of the project, and then uncommonly there is enough room for the rendered README content. There's nothing we can do about the fixed GitHub elements, but we can control the README and the number of files and directories in the root.

The "backstage" is a way to house content, like README content, without cluttering the root README. The backstage also has:

- [wish-list.md](wish-list.md): General clean-ups, TODOs and things I wish to implement for this project.
- [done.md](done.md): Items from the *Wish List* that are now considered done, skipped or obsoleted.


## The Root README

The root `README.md` has an `Overview` section that includes an incomplete index of important top-level directories. Format the index as a flat bullet list using this shape:

- `[dir/](dir/)`: `One line description.`

The `One line description` is an exact literal copy of the one-line descriptions that are present in a directory's own README.md. In fact, my convention of having a "one line top level description" is important. This one liner is always carefully created and concise. There's no reason to restate it differently in the index, please copy it verbatim.

In the index one-liner copy, preserve markdown emphasis and links. For directories without a README or one-liner, keep the index description blank.


## Agent Instructions

This section is for LLM-based agentic implementors.

You will mostly get direction and instructions from other sources, like global instructions, global agent skills, enabled MCP servers, or just by reading the regular `README.md` files version controlled in this repository.

In fact, when it comes to finding and producing agent instructions: I have one guiding principle: *Reduce, Reuse and Recycle*. I want you to:

- Reduce the amount of custom instructions that you generate anew
- Reuse the general direction, decisions, and implicit knowledge in the code and READMEs
- Recycle sections of a README or block comments in code to make a sharper point about instructions

In other words, I expect you to glean instructions from the whole codebase instead of relying on anything in the `AGENTS.md` file. Conversely, when you have a desire to encode new instructions, try to find a way to slot it into an existing place. Rewording and restructuring is always better than pure addition if possible.

For example, if you are missing context about one of the subprojects, consider adding an entry for it in the root README.md. Consider adding a README.md in its own directory, if missing.

Only if you have truly agent-specific instructions (like Cursor Cloud), then add them as a new section in the backstage README.
