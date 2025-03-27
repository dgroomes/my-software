# nushell

Nushell code and config that supports my personal workflows.


## Overview

I've made the transition to Nushell. The language has types, the docs are great, and the feature set is huge.

While I think Python is compelling for *script-sized programs*, I think Nushell is compelling for traditional
scripting. Nushell has the vibe of a full-blown programming langauge because it has variables, loops, data structures,
and functions, but importantly it still has the *spirit of the shell*: the Unix pipeline model and a terse grammar which
can sometimes be inscrutable. This is a strong combination.

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
  do backup config; do install config
  ```

We want to version control quite a bit. There is a tendency of tools like Nushell itself, Atuin and Starship to generate
a config file that then becomes your own to manage. That's perfectly fine. And the way I manage it is to version control
it. Our homebase for configuration is `<$nu.config-path>/config.nu`, but thankfully Nushell makes it easy to
modularize our code across other files:

* `scripts/` for **library code** 
* `vendor/autoload/` for **configuration code**

## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [ ] Nushell support in Intellij? Intellij Ultimate has LSP support now and [Nushell has an LSP](https://github.com/nushell/nushell/tree/main/crates/nu-lsp).
* [ ] How can I integrate Nushell with Raycast? I don't want go overboard with an integration, but I want to know what's
  possible.
* [ ] Use git instead of the `.bak` backup strategy. In general, I've been holding this strategy in my back packet. Seems like a
  good use.
* [ ] Keep experiment with `itrash` and `irm`. In general I want a compressed workflow for interactively deleting things.
  And a compressed workflow for deletes is counterintuitive. You don't want minimum key presses. You want minimum think
  time. When deleting with `rm ...` you should think deeply and slowly so you don't make a big mistake. With an
  interactive delete workflow, you initiate the command, and then ostensibly you're presented with a summary like "3 files, 123Kb"
  or something, and you can quickly know that you're safe to delete it. Refer back to this code: <https://github.com/dgroomes/my-software/blob/64224b151e64db01f068d3d806875a9eeaa9aac1/nushell/scratch.nu#L77>.
* [ ] Interactive file selection for context building. I love bundling full projects to pass to the LLM but often they
  are too big and I can't whittle it down. I need to go from the reverse direction. Start with nothing and layer in
  files/dirs. I think I can identify big chunks quickly enough. Interactive flow.
* [x] DONE Fix completion for `git`. I think this was a regression when I deleted my "symlinking completion" Perl script
  because there is a weird case for `git` completions because they ship with `git-completion.bash` and `git-prompt.sh.
* [x] DONE Move completer into own file
* [ ] Replace 'install-nu-scripts-sourcer' with just configuring path to completions? or symlinking? 
* [x] DONE For user scripts, since Nushell 0.102.0, use `autoload/` instead of `vendor/autoload`. I'll keep
  Atuin, Zoxide and Starship in `vendor/` even though I customized some of them.
* [ ] Consider retiring the 'do activate' trick. Clever but wouldn't be surprised if it broke. What people seem to be
  doing for the virtual env use-case is to use key bindings. I'm missing a few things from the overall experience too,
  like a compressed workflow to deactivate, and also a PS1 indicator. The problem I'm having in practice is activating
  in one directory, moving to another, and activating again... So I guess consider how to make that better. Auto-deactivate?
* [x] DONE (this was way harder than I thought but happy with the result and very happy with the strategy docs in shell-launcher.zsh) No more launching Nushell from Bash. Make the inversion. Nushell can be the main thing, and we can launch Bash
  from Nushell to accommodate the VSCode/Cursor initialization stuff. Mainly, I just want to consolidate some of the last
  config in `.bash_profile` into my Nushell config.
* [ ] Check out the standard library that was newly released, like the `path add` command.
* [ ] Flesh out debugging/obervability for my Nushell sourcing/setup. I think I'd like something like, use `env.nu` just
  to set an env var like "DEBUG = true" and then by convention key off of that manually in every script and print the
  script name at the top of the script. The common problem I'm running into is understanding what files are being sourced
  and in what order.
* [ ] Locate the last Bash stuff elsewhere into here and re-document `nushell/` in a more general `shell` way. I want to
  keep the name as `nushell` so I can zoxide to it quickly and because it's mostly nushell. As part of this, take the
  strategy notes in `shell-launcher.zsh` into this README.
* [x] DONE Rewrite the `brew --prefix <formula>` stuff to instead just manually locate that file on the file system using Nushell
  instead of calling `brew` because brew is way slow (Ruby startup time).


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
* [x] DONE (pretty good; I skipped do-deactivate) `do-activate` and `do-deactivate` commands to help me with a conventional workflow of `do.nu` files, using Nushell overlays. 
* [ ] OBSOLETE (Time has moved on. Not as good a fit. Don't care) Use the conventional place for putting Nushell scripts designed to be sourced: `$nu.default-config-dir/scripts`.
  I'm curious to know how entrenched this convention is. How much do I get for free by following it? I do like the
  convention. The Nushell constraint on not being able to source from a directory is proving to be awkward. My `nu_script_source.nu`
  is in the style of a known workaround that I've seen others do: <https://discord.com/channels/601130461678272522/615253963645911060/1195458767622516738>.
* [ ] OBSOLETE (The need for mutable was correct; I'm going with `misc.nu`) I think I need to not version control `env.nu`. I need mutable content to some degree among my Nushell config
  system and I think `env.nu` is probably the ticket. For common fixtures that I want evaluated at the `env.nu` eval
  time, I can jam them into a file like `env-common.nu` and source that from `env.nu`.
* [x] DONE In `run-from-readme`, execute `bash` snippets in Bash.
* [x] DONE Split up `config.nu`. It's huge. How much can I use `use` instead of `source`? I'm trying to remember why this
  even matters.
* [ ] OBSOLETE (Time has moved on. Not as good a fit. Don't care) If a 'do' module is already active, we want to completely unload all commands and symbols it defines before
  loading another 'do.nu' script (it could be the same one, an edited version of the same one, or a totally diff one).
  `overlay hide do` should totally work, and that command seems to work as designed when I use it from the REPL, but I
  wasn't having good luck when calling it from the hook function. Try again? Try making two hooks? Maybe that will work.
  Why does this matter? It's really annoying to crowd the command/autocomplete list as I rapidly iterate on a 'do.nu' script.
* [ ] OBSOLETE (Time has moved on. Not as good a fit. Don't care) Clean up sourcing code (env, core, etc.). I had to source Atuin last because ostensibly I'm overwriting hooks in
  the env/core config. Just re-consider this flow.
* [x] DONE (kind of tricky, as always) Fix completions for `brew uninstall `. It's not listing installed packages.


## Reference

* [Nushell](https://www.nushell.sh)
* [nushell-playground](https://github.com/dgroomes/nushell-playground)
  * This is my own "study" repository for Nushell. 
