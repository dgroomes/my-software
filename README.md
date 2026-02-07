# my-software

My personal software: dot files, utility programs, setup instructions, and more.


## Overview

The most impactful component of this repository might be my [macOS Setup](#macos-setup) notes. It provides step-by-step
instructions I like to follow for setting up a new Mac. In this repository, I've also crammed in a wide range of other
personal tooling I've developed or am just experimenting with.


### `mac-os/`

My personal instructions for configuring macOS the way I like it and installing the tools I use.

See the README in [mac-os/](mac-os/).


### `bash/`

My Bash config and notes about Bash auto-completion (I always forget how to set this up!).

See the README in [bash/](bash/).


### `homebrew/`

A description of my Homebrew strategy.

See the README in [homebrew/](homebrew/).


### `java/`

Java code that supports my personal workflows.

See the README in [java/](java/).


### `javascript/`

JavaScript code that supports my personal workflows.

See the README in [javascript/](javascript/).


### `jetbrains/`

My configuration for JetBrains IDEs (e.g. Intellij and Android Studio).

> Essential tools for software developers and teams
> 
> <cite>https://www.jetbrains.com</cite>

See the README in [jetbrains/](jetbrains/).


### `karabiner/`

My configuration for the amazing tool *Karabiner-Elements* <https://github.com/tekezo/Karabiner-Elements>.

> Karabiner-Elements is a powerful utility for keyboard customization on macOS Sierra or later.
> 
> -- <cite>https://github.com/pqrs-org/Karabiner-Elements</cite>


### `nushell`

My Nushell configuration and scripts.

See the README in [nushell/](nushell/).


### `starship/`

My config file for Starship.

> The minimal, blazing-fast, and infinitely customizable prompt for any shell!
>
> -- <cite>https://github.com/starship/starship</cite>


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

- [ ] Consider restoring (at `b3154dde` and before) the shortcuts I had defined for `navi` (but no need to use `navi`). There was some good knowledge there, but I never wound
  up using `navi`.
- [ ] Consider restoring (at `b3154dde` and before) my usage of markdownlint. I still like it, but I just never got used to using it.
  learn them better. I think I should pare down the larger one-liners.
- [ ] Consider restoring (at `b3154dde` and before) my Postgres-related Bash functions. These were hard fought and useful. Maybe reimplement in
  Nushell. Alternatively, I often use Postgres in Docker. But still. (Same is true of the Mongo functions but not sure
  how much I'll ever use Mongo again.)
- [ ] I really want quick, keyboard-based diff review like I have in Intellij. See <https://github.com/microsoft/vscode/issues/24389>
- [ ] I want enhanced (LLM) search over my browser history. Safari somehow clobbers entries in my history, or at least
  they don't show up. It's almost like it consolidates multiple pages for the same host or something. For example, as I
  explore a new topic I'll look at official docs which are often scattered across multiple subsets of pages because of marketing
  reasons and/or the natural sprawl of a volunteer-driven project. Some of these pages are golden, but hard to discover.
  If I've found them once, then I want to find them again. Maybe I should use bookmarks/read-later more. Whatever it is,
  consider this story again. Apache Iceberg (and the branching into Hive stuff) is a good example of this.
- [ ] (aspirational) Finetune an LLM on parsing/extracting my TODO/WishList items. They aren't fully machine readable
  because of formatting differences and also I use different words sometimes (DONE, SKIP, HOLD, and I might make
  something up) so they aren't perfectly classifiable by keyword. I think this is a pretty good candidate for a
  low-parameter model which I can run on my computer. I would just start with few shot learning. The idea is, take the
  best parts of a task/project manager (Linear) and the low-tech approach of "just ad hoc markdown" (like I've done) and
  get more mileage out of it.
- [ ] In the scratch area, explore MCP in JetBrains. Maybe consider running Intellij in a DevContainer. Idk.
- [ ] Strategy. I need to capture some overarching software strategy notes. I need broad and specific stuff. I generally
  don't get a lot of long term leverage out of "text only" work products (that's why I have so many 'playground' repos
  that are code plus lots of "what" and "why" text). But, things have bubbled up. I need essetnially 'cursorrules' for
  myself and other LLMs to follow. For example, "smaller files" (maybe?) is a practical thing right now because the LLM
  tools have better success "replacing file contents" than "slice editing" a file (see aider state-of-the-art notes on
  this). Plus it's slow waiting for the LLM to replace the whole contents of a file. I don't want to run out of tokens.
  But... this is completely impractical. There's no way I'm going to generally confine myself to small files. Big files
  are often the best way to do things. Single-file scripts... An essay/blog. Still I need to capture the impactful
  strategy notes.
- [ ] Consider moving finished wish list items to own file so that we can save LLM tokens. I only want to ingest those 
  when doing refinement/history on my open wish list items (rare). Or... maybe consider using GitHub issues... but that's such an escalation. Or, create a "README"-like MCP tool that parses the finished section out. An agent would call this tool instead of reading the readme directly. Similarly, I might need a tool for updating (toggling) the status of items. I've already explored this but switched gears because of lack of experience with MCP/agents.
- [ ] Consider `my-project-conventions` agent/tools. If it's my project (heuristics, in my GitHub user) and follows some other patterns (e.g. "wish list" section), then find and fix conventional issues (e.g. double newline, naming of sections, single line intro, etc).
- [ ] I need a way to install the launcher. With the Java launcher, I use a Gradle plugin. But with npm there isn't as strong a story for this (you can make an argument, but I know enough to not try it). I'll just use Nushell.
- [ ] Use Bun instead of npm in my JavaScript projects where possible. I've already paid the learning cost and Bun is very fast.
- [x] DONE Spring cleaning. There's quite a bit of stuff I've been holding onto because I thought I might use it or complete but haven't. I need to lean this codebase out. I can delete it and it'll still be in vcs. So let's do it.
   - DONE Delete whole sub-projects and track them in a "consider revising" with list item
   - DONE Remove finished wish list items. This one hurts a little... but they take up context windows and my own space too. Gotta drop it. It's still minable in vcs.
- [ ] Consider bringing back any of these archived projects that were removed from this repository in the commit after 31f63e651c3c30921294dfcaccbc668329ed8a4b:
   - `go/pkg/go-body-omitter`
   - `go/pkg/posix-nushell-compatibility-checker`
   - `java/java-body-omitter`
   - `karabiner/assets/complex_modifications/move-between-tabs.json`
   - `karabiner/assets/complex_modifications/open-apps.json`
   - `mcp/` This was neat but just learning from first principles. I've captured the knowledge and tricks elsewhere.
   - `python/text-condenser` Gestated into a decent vision. Recover the plan/language.
   - `rust/nushell-ast-printer`
- [ ] Split up Go programs into own sub-projects. I've really only found Gradle to be an effective monorepo tool. It splits things in separate compilation units and dependency trees. Nothing else is as powerful and that's perfectly fine. I'll keep my Java/Kotlin co-mingled by a single Gradle project, but READMEs have to go in their own sub-projects.
- [ ] PARTIAL Sandbox profile should allow `mkdir` and `pwd` don't know why these are blocked. `(allow default)` allows sub-processes so what's going on?
   - DONE Allow file write to my conventional '~/.shell-debug.log'
- [ ] Rewrite Git aliases as just shell aliases (Nushell). I don't see super see the point of git aliases plus I already re-wrap them in shorter shell aliases anyway ('gl' for 'git lg' for 'git log ...')
- [ ] Actually incorporate the Claude *Skills*. The one I added is LLM inferred (though pretty good) and based on a wide upgrade of my junit-playground.
- [x] DONE (the remaining tasks are tracked in the subproject) maxGraph simple editor. I like Mermaid diagrams but I need some architecture diagrams which tend to include more boxes and arrows, and the procedural layout is not good for that, the diagrams become squished and odd. Turns our maxGraph exists, which I didn't realize is well-maintained fork and descendent of Draw.IO's mxGraph. Very neat.
  - DONE Draft the project
