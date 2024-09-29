# nushell

Nushell configuration, scripts, and notes.


## Overview

I'm making a transition to Nushell, especially since I've had success in learning and using the basics of the shell in
my [nushell-playground](https://github.com/dgroomes/nushell-playground) repository. The language has proper types, the
docs are great, and the feature set is huge. I'm enthusiastic about writing fewer Bash scripts. While I think Python is
compelling for *script-sized programs*, I think Nushell is very compelling for traditional scripting. When you use
Nushell, there is no struggle with paths, loops, variables, functions, and return values. It still has the *spirit of the
shell*: the Unix pipeline model and a terse grammar which can sometimes be inscrutable.

My favorite feature may be its standard library of commands. I love that I can get the basename of a file, parse JSON,
and make HTTP requests without any external dependencies.

Miscellaneous notes:

* ```nushell
  overlay use --prefix do.nu
  ```
* ```nushell
  do install nu_scripts_sourcer ~/repos/opensource/nu_scripts
  ```
* ```nushell
  do backup standard; do install standard
  ```

We want to version control quite a bit. There is a tendency of tools like Nushell itself, Atuin and Starship to generate
a config file that then becomes your own to manage. That's perfectly fine. And the way I manage it is to version control
it. Because of that, I'm also going to want a modular approach when it comes to my Nu source files. I want this `nushell/`
directory to have a full grip on my Nushell stuff. I feel a bit lost about `env.nu` but I'll get there. The docs are
good: <https://www.nushell.sh/book/configuration.html>. Also see <https://www.nushell.sh/book/modules.html#dumping-files-into-directory>.


## Wish List

General clean-ups, TODOs and things I wish to implement for this project

* [ ] Nushell support in Intellij? Intellij Ultimate has LSP support now and [Nushell has an LSP](https://github.com/nushell/nushell/tree/main/crates/nu-lsp).
* [ ] How can I integrate Nushell with Raycast? I don't want go overboard with an integration, but I want to know what's
  possible.
* [ ] Use the conventional place for putting Nushell scripts designed to be sourced: `$nu.default-config-dir/scripts`.
  I'm curious to know how entrenched this convention is. How much do I get for free by following it? I do like the
  convention. The Nushell constraint on not being able to source from a directory is proving to be awkward. My `nu_script_source.nu`
  is in the style of a known workaround that I've seen others do: <https://discord.com/channels/601130461678272522/615253963645911060/1195458767622516738>.
* [ ] I think I need to not version control `env.nu`. I need mutable content to some degree among my Nushell config
  system and I think `env.nu` is probably the ticket. For common fixtures that I want evaluated at the `env.nu` eval
  time, I can jam them into a file like `env-common.nu` and source that from `env.nu`.
* [x] In `run-from-readme`, execute `bash` snippets in Bash.


## Finished Wish List Items

* [x] DONE (although I didn't version control it) Create an iTerm profile for Nushell. This way I don't have to change my login shell to Nushell. Not even close to
  ready for that.
* [x] DONE Consider using Starship
* [x] DONE What is Nushell's history and Ctrl-R (or the equivalent) support? Should I jump straight to atuin?
* [x] DONE Define a `cd-repo` function like I have for Bash. Maybe study zoxide?
   * Update: need to read this page: [External Completers](https://www.nushell.sh/cookbook/external_completers.html)
   * DONE Make it work for more than just `personal/`
   * SKIP (wait I found `input list` command which supports fuzzy search... <https://www.nushell.sh/commands/docs/input_list.html>) Do an `fzf` implementation. I think that's just the state of things. And `fzf` is still a great tool. For
     reference, see <https://github.com/nushell/nushell/issues/1275>.
   * DONE Explore `input list`
* [x] DONE Load completions from ["nu_scripts"](https://github.com/nushell/nu_scripts/tree/4eab7ea772f0a288c99a79947dd332efc1884315/custom-completions)
   * This is a little tricky to bootstrap.
   * ~~Hmm, it seems like `source` in a script that itself is a `source` has no effect. I don't see any error message, but
     if I source completion script directly from the shell I do get completions (`git`).~~
   * Update: no sourcing in sourcing does work... And now I get `source` and `use` better, and they are parse-time
     things not eval-time things so you can't conditionally use them. I need dynamic content in a static (reliable) file.
     I need to codegen it blank (bootstrap) or with completions (later bootstrap).
* [x] DONE How do I copy the last command to clipboard? I should make a command/alias for that.
* [x] DONE Fix `cd-repo` so that when it is exited, it doesn't print an error.
* [x] DONE (I implemented an installation/backup script) File strategy.
* [x] DONE Implement a `git switch default pull` command.
* [x] DONE Bash completion via external completer. This was a large effort.
* [ ] SKIP (Not feasible. SDKMAN is all bash code, which makes sense. I thought maybe there was a core of Groovy/Java, but it's all Bash) 'How can I use SDKMAN with Nushell? It only supports Bash and Zsh and there's quite a bit of shell code. I would have
  to write a decent amount of Nu code, might be feasible.
* [x] DONE Java version management: switch/install. This is going to be somewhat sophisticated, but also should play to Nushell's
  strengths and is a good opportunity for me to learn a bit more about the Adoptium/Temurin project for OpenJDK (as far as
  a user goes, not a contributor). Maybe figure something out for Gradle too but that's diminishing returns.
   * I think the hard part is done. I went with using my own Homebrew formula for installing the JDK (a key point is
     just having a convention place to put the JDK files).
   * DONE Basic "activation" in programmatic Nu code.
   * DONE Support switching
   * DONE Activate an OpenJDK at Nushell startup. 
* [x] DONE Use `chsh` to effectively use Nushell as the login shell but by first bootstrapping it with Bash. I don't feel
  that it's feasible or wise to use Nushell directly as the login shell. I'm concerned about the annoying nature of
  bootstrapping Nushell's environment within Nushell's own configuration/initialization scripts. I would much rather,
  bootstrap a Bash environment and call all the many Bash-based initialization things like `brew shellenv` and then `exec`
  `nu`. Plus, I don't think it's feasible or wise to stop understanding Bash. It will remain an important piece in my
  environment for a long time, side-by-side Nushell.
    * `sudo cp ~/repos/personal/my-config/nushell/nushell.bash /usr/local/bin`
    * `sudo bash -c 'echo /usr/local/bin/nushell.bash >> /etc/shells'`
    * `chsh -s /usr/local/bin/nushell.bash`
* [x] DONE I'm not getting file completions when using commands like `subl`. This is annoying. I think it's the issue
  described by this GitHub issue comment <https://github.com/nushell/nushell/issues/6407#issuecomment-1227250012>
  * > The current issue is that the external completer function doesn't differenciate between an empty result (nothing to complete at current position) and an external completer not being invoked (file fallback).
* [x] DONE Improve robustness of the 'one-shot-bash-completion.bash' script. Better error handling, more notes,
  use `_comp_load` instead of `_comp_complete_load` because its more direct and the exit code can be keyed off of. I
  think maybe there was a change in 'bash-completion', but either way, these changes are good.
* [ ] IN PROGRESS `do-activate` and `do-deactivate` commands to help me with a conventional workflow of `do.nu` files, using Nushell overlays. 


## Reference

* [Nushell](https://www.nushell.sh)
* [nushell-playground](https://github.com/dgroomes/nushell-playground)
  * This is my own "study" repository for Nushell. 
