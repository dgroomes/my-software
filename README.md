# my-software

My personal software: dot files, utility programs, setup instructions, and more.


## Overview

The most useful component of this repository is the [My macOS Setup](#my-macos-setup) section below. It provides
step-by-step instructions I like to follow for setting up a new Mac.

The rest of the repository is organized in the following directories:


### `mac-os/`

My personal instructions for configuring macOS the way I like it and installing the tools I use.

See the README in [mac-os/](mac-os/).


### `bash/`

My Bash config and notes about Bash auto-completion (I always forget how to set this up!).

See the README in [bash/](bash/).


### `homebrew/`

A description of my Homebrew strategy.

See the README in [homebrew/](homebrew/).


### `iterm2/`

My iTerm2 config.

> iTerm2 is a terminal emulator for macOS that does amazing things.
> 
> -- <cite>https://iterm2.com</cite>


### `java/`

Java code that supports my personal workflows.

See the README in [java/](java/).


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

* [ ] Consider restoring (at `b3154dde` and before) the shortcuts I had defined for `navi`. There was some good knowledge there, but I never wound
  up using `navi`.
* [ ] Consider restoring (at `b3154dde` and before) my usage of markdownlint. I still like it, but I just never got used to using it.
  learn them better. I think I should pare down the larger one-liners.
* [ ] Consider restoring (at `b3154dde` and before) my Postgres-related Bash functions. These were hard fought and useful. Maybe reimplement in
  Nushell. Alternatively, I often use Postgres in Docker. But still. (Same is true of the Mongo functions but not sure
  how much I'll ever use Mongo again.)
* [ ] Why isn't `enter_accept = true` working for Atuin? It has no effect.
* [x] DONE Poetry completion isn't working... I've been here before
* [x] DONE Completion isn't working for brew... We've [been here before](https://github.com/dgroomes/my-software/commit/15339d8e51b7649807669d508679b525feb9e7e5)


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
