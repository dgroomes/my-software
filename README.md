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

* [ ] Consider restoring (at `b3154dde` and before) the shortcuts I had defined for `navi` (but no need to use `navi`). There was some good knowledge there, but I never wound
  up using `navi`.
* [ ] Consider restoring (at `b3154dde` and before) my usage of markdownlint. I still like it, but I just never got used to using it.
  learn them better. I think I should pare down the larger one-liners.
* [ ] Consider restoring (at `b3154dde` and before) my Postgres-related Bash functions. These were hard fought and useful. Maybe reimplement in
  Nushell. Alternatively, I often use Postgres in Docker. But still. (Same is true of the Mongo functions but not sure
  how much I'll ever use Mongo again.)
* [x] DONE (It's a known bug in Atuin) Why isn't `enter_accept = true` working for Atuin? It has no effect.
* [x] DONE Poetry completion isn't working... I've been here before
* [x] DONE Completion isn't working for brew... We've [been here before](https://github.com/dgroomes/my-software/commit/15339d8e51b7649807669d508679b525feb9e7e5)
* [x] DONE Revert to a more standard (non high contrast) color theme for Ghostty and instead use a more targeted approach:
  create higher contrast color themes/settings in specific tools like Nushell and LS_COLORS (already done). I realized
  that modifying the colors of the 256 ANSI colors (at least beyond the base ones) is kind of a kludgy and imperfect
  thing to do because it crushes most of those colors, and it doesn't even solve a global contrast problem because CLI
  tools can just use whatever color (hex) they want (like my own fuzzy finder). So forget it. If there is a CLI/TUI tool
  that has particularly bad contrast, and codes to the ANSI-256 colors, and doesn't have its own color configuration, then
  I'll consider "redefining ANSI 256", but overall I think that should be rare and I don't to redefine system things
  without big thought.
* [x] DONE Try out Nushell's new "vendor auto load" configuration feature
* [x] DONE (good enough for now; I have to use Obsidian to get more of an opinion) Obsidian + LLM. I want to browse and search my README files in a convenient way (*compressed workflow*). I have a decent corpus
  of content in the README files of my many playground-style GitHub repositories. I often want to copy specific pieces
  from them and find snippets of knowledge (sometimes I know I have done something but can't find the right repository).
  My overarching desire is to be able to have semantic search over my hard-earned writing (I write for "me" as the main
  audience). While I can (and do) use grep and GitHub search, I think Obsidian plus LLMs (either local or via hosted LLM APIs),
  is a good approach in 2025. There is a neat Obsidian plugin called [Smart Connections](https://github.com/brianpetro/obsidian-smart-connections)
  that I want to try. As part of this idea, I need a strategy for locating the markdown files into an Obsidian vault.
  Obsidian does not like symlinks. So, my thought is that I should prefer a copying mechanism.
   * DONE Script out some code and notes. It's open ended.
   * DONE Install "Smart Connections". Do some embeddings and try it out.
   * Note: I'm also interested in semantic search over the many comments, function names, etc, in my actual code... but
     there is not an obvious way to do this... Although I'm tempted to parse out the comments (I've parsed out Go and
     Java with the proper compiler toolchains so, it's totally possible) and embed/index them. But the presentation part
     is hard
* [ ] I really want quick, keyboard-based diff review like I have in Intellij. See <https://github.com/microsoft/vscode/issues/24389>
* [x] DONE Remove duplicate strings in prompt bundles. This is what I want to use in principle: <https://github.com/google-research/deduplicate-text-datasets>
  Somewhat ambitious, but I think this has the potential to be as successful and appropriate as my `fzf` port. The
  source code is relatively small. I'd like to reimplement a toy version of it in Kotlin for short term. After I grok it,
  I can consider rewriting it Rust but I expect I will never need that performance. My prompt files will only ever be
  like a couple megabytes max, right?
   * DONE Incorporate deduplication into bundling code.
* [ ] I want enhanced (LLM) search over my browser history. Safari somehow clobbers entries in my history, or at least
  they don't show up. It's almost like it consolidates multiple pages for the same host or something. For example, as I
  explore a new topic I'll look at official docs which are often scattered across multiple subsets of pages because of marketing
  reasons and/or the natural sprawl of a volunteer-driven project. Some of these pages are golden, but hard to discover.
  If I've found them once, then I want to find them again. Maybe I should use bookmarks/read-later more. Whatever it is,
  consider this story again. Apache Iceberg (and the branching into Hive stuff) is a good example of this.
* [ ] Java 24. Adoptium is publishing this in the next few days. I did an ea version but want the full one.
* [ ] (aspirational) Finetune an LLM on parsing/extracting my TODO/WishList items. They aren't fully machine readable
  because of formatting differences and also I use different words sometimes (DONE, SKIP, HOLD, and I might make
  something up) so they aren't perfectly classifiable by keyword. I think this is a pretty good candidate for a
  low-parameter model which I can run on my computer. I would just start with few shot learning. The idea is, take the
  best parts of a task/project manager (Linear) and the low-tech approach of "just ad hoc markdown" (like I've done) and
  get more mileage out of it.
* [ ] In the scratch area, explore MCP in JetBrains. Maybe consider running Intellij in a DevContainer. Idk.
* [ ] Strategy. I need to capture some overarching software strategy notes. I need broad and specific stuff. I generally
  don't get a lot of long term leverage out of "text only" work products (that's why I have so many 'playground' repos
  that are code plus lots of "what" and "why" text). But, things have bubbled up. I need essetnially 'cursorrules' for
  myself and other LLMs to follow. For example, "smaller files" (maybe?) is a practical thing right now because the LLM
  tools have better success "replacing file contents" than "slice editing" a file (see aider state-of-the-art notes on
  this). Plus it's slow waiting for the LLM to replace the whole contents of a file. I don't want to run out of tokens.
  But... this is completely impractical. There's no way I'm going to generally confine myself to small files. Big files
  are often the best way to do things. Single-file scripts... An essay/blog. Still I need to capture the impactful
  strategy notes.


## Finished Wish List Items

* [x] DONE System for measuring the time it takes to load scripts in `.bashrc` and `.bash_profile`. I want to do something
  like [this very cool project](https://github.com/colindean/hejmo/blob/0f14c6d00c653fcbb49236c4f2c2f64b267ffb3c/dotfiles/bash_profile#L93)!
* [x] DONE (The answer is: never use eager completion loading) Loading my bash completions is slow. Doesn't bash completions support lazy loading? I have some good notes in `bash/BASH_COMPLETION.md`.
  Maybe most software still only provides v1 completion (which doesn't support lazy/on-demand)...
* [x] DONE Create my personal framework/strategy for managing "scripts to source during Bash shell initialization time"
    * DONE Scaffold out a Perl script
* [ ] SKIP Add more external documentation to `bb` (the internal documentation in the '--help' is already extremely thorough)
* [ ] SKIP (bb is complete) Implement the fifo/domain-socket -based benchmarking described in `bb`
* [ ] (SKIP: virtual environments satisfy Python version switching) Python SDK management. Don't bother with custom formula. Just use the core ones, which already include
  3.9, 3.10, 3.11 and 3.12. That's perfect. UPDATE: I think Python switching is not as necessary as Java or Node.js
  switching because we often use virtual environments. So, in a Python project, you typically activate its virtual env
  and that's your way of switching Python versions. And for one-off scripts, would I just be using the latest Python
  anyway? I'm going to skip this for now.
* [x] DONE Node.js SDK management (I think this should be totally feasible since I figured this out with OpenJDK and am happy
  with that).
* [x] DONE Make a "Java program launcher" in Go. In any interpreted program, (Java, Python, Ruby, JavaScript), the program
  needs to be run with an interpreter (JVM, `python`, `ruby`, `node`, etc.). This is totally fine, but distributing
  these programs is often a challenge because the user needs to have the interpreter installed, and it needs to be a
  compatible version, and it needs to be discoverable when launching the program. In Java, we have things like the `JAVA_HOME`
  environment variable to help with that. But that doesn't help with version compatibility. By contrast, programs that
  compile to an executable binary (e.g. Go, C) are easy to distribute. They are "all-in-one". (To be fair, the same
  distribution headache is true for Go and Co programs if they link to shared libraries). I have a Java program in `java/markdown-code-fence-reader`
  that works as long as my `JAVA_HOME` is a Java 21 JDK, but my shell environment differs per project. I want to solve
  this scenario.
    * DONE Go side
    * DONE Gradle side
* [x] DONE Properly add Nushell steps to instructions. Bootstrapping is important.
* [x] DONE `pipx` shell completion is broken. It's working in bash. Not sure why not working in Nushell. Strange, even
  `BASH_COMPLETION_INSTALLATION_DIR=/opt/homebrew/opt/bash-completion@2 ./one-shot-bash-completion.bash "pipx "` works.
* [x] DONE `brew` completion doesn't work.
* [x] DONE Create a `java-body-omitter` program that works just like the `go-body-omitter` program but for Java.
* [x] DONE Can I get rid of `bb`? I no longer have a need for the speed-up of bb and also my spread of bash files is tiny
  now because I'm on Nushell. The catalyst is that `brew shellenv` is misbehaving now because it overwrites the PATH
  with some hardcoded stuff... not going to bother figuring that out.
* [x] DONE Split out instructions into own directory. It's worked well but now this repo is `my-software`, much more broad.
