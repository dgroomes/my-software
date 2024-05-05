# nushell

Nushell configuration, scripts, and notes.


## Overview

I'm making a transition to Nushell, especially since I've had success in learning and using the basics of the shell in
my [nushell-playground](https://github.com/dgroomes/nushell-playground) repository. The language has proper types, the
docs are great, and the feature set is huge. I'm enthusiastic about writing fewer Bash scripts. While I think Python is
compelling for *script-sized programs*, I think Nushell is very compelling for traditional scripting. When you use
Nushell, there is no struggle with paths, loops, variables, functions, return values, or inscrutable syntax. 

Miscellaneous notes:

* ```text
  use nu-functions.nu *
  ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project

* [ ] Create an iTerm profile for Nushell. This way I don't have to change my login shell to Nushell. Not even close to
  ready for that.
* [ ] Consider using Starship
* [ ] What is Nushell's history and Ctrl-R (or the equivalent) support? Should I jump straight to atuin?
* [ ] IN PROGRESS Define a `cd-repo` function like I have for Bash. Maybe study zoxide?
   * Update: need to read this page: [External Completers](https://www.nushell.sh/cookbook/external_completers.html)
   * DONE Make it work for more than just `personal/`
   * Do an `fzf` implementation. I think that's just the state of things. And `fzf` is still a great tool. For
     reference, see <https://github.com/nushell/nushell/issues/1275>.
* [ ] Nushell support in Intellij? Intellij Ultimate has LSP support now and [Nushell has an LSP](https://github.com/nushell/nushell/tree/main/crates/nu-lsp).
* [ ] Get completions working for `gh`. Is that even possible?
* [ ] How can I integrate Nushell with Raycast? I don't want go overboard with an integration, but I want to know what's
  possible.
* [ ] How do I copy the last command to clipboard? I should make a command/alias for that.


## Reference

* [Nushell](https://www.nushell.sh)
* [nushell-playground](https://github.com/dgroomes/nushell-playground)
  * This is my own "study" repository for Nushell. 
