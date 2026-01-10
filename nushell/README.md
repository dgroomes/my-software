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

- ```nushell
  overlay use --prefix do.nu
  ```
- ```nushell
  do install nu_scripts_sourcer ~/repos/opensource/nu_scripts
  ```
- ```nushell
  do backup config; do install config
  ```

We want to version control quite a bit. There is a tendency of tools like Nushell itself, Atuin and Starship to generate
a config file that then becomes your own to manage. That's perfectly fine. And the way I manage it is to version control
it. Our homebase for configuration is `<$nu.config-path>/config.nu`, but thankfully Nushell makes it easy to
modularize our code across other files:

- `scripts/` for **library code** 
- `vendor/autoload/` for **configuration code**

## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

- [ ] Nushell support in Intellij? Intellij Ultimate has LSP support now and [Nushell has an LSP](https://github.com/nushell/nushell/tree/main/crates/nu-lsp).
- [ ] How can I integrate Nushell with Raycast? I don't want go overboard with an integration, but I want to know what's
  possible.
- [ ] Use git instead of the `.bak` backup strategy. In general, I've been holding this strategy in my back packet. Seems like a
  good use.
- [x] DONE (using `rip2`) Keep experimenting with `itrash` and `irm`. In general I want a compressed workflow for interactively deleting things.
  And a compressed workflow for deletes is counterintuitive. You don't want minimum key presses. You want minimum think
  time. When deleting with `rm ...` you should think deeply and slowly so you don't make a big mistake. With an
  interactive delete workflow, you initiate the command, and then ostensibly you're presented with a summary like "3 files, 123Kb"
  or something, and you can quickly know that you're safe to delete it. Refer back to this code: <https://github.com/dgroomes/my-software/blob/64224b151e64db01f068d3d806875a9eeaa9aac1/nushell/scratch.nu#L77>.
   - DONE Update: Trying out <https://github.com/MilesCranmer/rip2>
- [ ] Interactive file selection for context building. I love bundling full projects to pass to the LLM but often they
  are too big and I can't whittle it down. I need to go from the reverse direction. Start with nothing and layer in
  files/dirs. I think I can identify big chunks quickly enough. Interactive flow.
- [ ] Replace 'install-nu-scripts-sourcer' with just configuring path to completions? or symlinking?
- [ ] Consider retiring the 'do activate' trick. Clever but wouldn't be surprised if it broke. What people seem to be
  doing for the virtual env use-case is to use key bindings. I'm missing a few things from the overall experience too,
  like a compressed workflow to deactivate, and also a PS1 indicator. The problem I'm having in practice is activating
  in one directory, moving to another, and activating again... So I guess consider how to make that better. Auto-deactivate?
- [ ] Check out the standard library that was newly released, like the `path add` command.
- [ ] Flesh out debugging/observability for my Nushell sourcing/setup. I think I'd like something like, use `env.nu` just
  to set an env var like "DEBUG = true" and then by convention key off of that manually in every script and print the
  script name at the top of the script. The common problem I'm running into is understanding what files are being sourced
  and in what order.
- [ ] Locate the last Bash stuff elsewhere into here and re-document `nushell/` in a more general `shell` way. I want to
  keep the name as `nushell` so I can zoxide to it quickly and because it's mostly nushell. As part of this, take the
  strategy notes in `shell-launcher.zsh` into this README.
- [ ] Move `LS_COLORS` to `autoload/`. Files in `autoload` are only invoked for interactive scripts I think. Not that this
  really moves the needle on performance but the `LS_COLORS` is so huge that I need it to not clutter the token count of
  `config.nu`.


## Reference

- [Nushell](https://www.nushell.sh)
- [nushell-playground](https://github.com/dgroomes/nushell-playground)
  - This is my own "study" repository for Nushell. 
