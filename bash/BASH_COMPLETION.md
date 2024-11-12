# Bash Completion

Bash completion is a general feature of Bash, but is also conflated with a third-party project of the same name:
<https://github.com/scop/bash-completion>.

Bash completion is more formally known as its "programmable completion" feature. See 
<http://tldp.org/LDP/abs/html/tabexpansion.html>.

`bash-completion` (<https://github.com/scop/bash-completion>) the project describes itself as

> bash-completion is a collection of command line command completions for the Bash shell, collection of helper functions
> to assist in creating new completions, and set of facilities for loading completions on demand as well as installing 
> them.

Notice how the `bash-completion` project name is stylized with a hyphen and lowercase. We will stick with this naming
convention to disambiguate it from the Bash feature.


## bash-completion v2

<https://formulae.brew.sh/formula/bash-completion@2>

v2 is the new version. It contains a large amount of built-in completions for a diverse set of programs like `chmod`, 
`7z`, `jq` `kill`, `ssh`, `curl`, `java`. See the full list at <https://github.com/scop/bash-completion/tree/master/completions>.

The relevant files (including symlinks) and directories are: 

* `/opt/homebrew/etc/profile.d/bash_completion.sh`
  * This file gets sourced from `.bash_profile`.
  * This file symlinks to `../../Cellar/bash-completion@2/2.13.0/etc/profile.d/bash_completion.sh`
* `/opt/homebrew/Cellar/bash-completion@2/2.13.0/etc/profile.d/bash_completion.sh`
  * This is the configuration file hook. It loads bash-completion.
* `/opt/homebrew/Cellar/bash-completion@2/2.13.0/share/bash-completion/bash_completion`
  * This is the bash-completion program itself.
* `$HOME/.local/share/bash-completion/completions/`
  * I think this is where you are supposed to put v2 completions that you yourself write
* `/opt/homebrew/etc/bash_completion.d/`
  * This is where Homebrew formulas often install v1 (legacy) completions via symlinks.
  * For example, for me, I find symlinks to completion scripts for `brew`, `cmake`, `gh`, `rg` and more.  
* `/opt/homebrew/Cellar/bash-completion@2/2.13.0/share/bash-completion/completions`
  * These are the completions that come bundled with bash-completion. There are a lot (910 at the time of writing). There are completions
    for commands like `7z`, `make`, `curl`, and interestingly many variations of Python like `python`, `python3`, `python3.3` etc.

The environment variable `BASH_COMPLETION_COMPAT_DIR` is a compatibility option to enable `bash-completion v2` to load
third-party completion scripts that were designed in the era of `bash-completion v1`. For example, set `BASH_COMPLETION_COMPAT_DIR="/opt/homebrew/etc/bash_completion.d/"`
if you want to load those completions. But loading completion scripts in this way is a problem... read the next section
for more information.


## **The Big Problem**

Legacy bash-completion v1 completions make for a slow "start up a new shell" experience. This is because the "bash-completion"
program [sources all these completions eagerly](https://github.com/scop/bash-completion/blob/b1d163e99e17bcfbc79ee1b6151d8295307d8bc6/bash_completion#L2634).
The 'docker' completion script, in particular, is slow. It takes roughly 0.5 seconds to source on my machine. This is
actually really annoying because I open new shells all the time, especially by way of Intellij's convenient "run this
Markdown shell snippet in an embedded terminal window" feature, which I use constantly I believe is "the way".


## A Workaround

My workaround for the slowness problem is to disable the eager loading of the v1 completion scripts. Interestingly,
I've found that the v1 completion scripts are perfectly fine to treat as v2 script. They can be loaded lazily along with
the regular v2 completion scripts if I just re-located them (or symlink them) to the v2 location. I do not understand
why `bash-completion` v2 even loads completion scripts the legacy way if loading them lazily should "just work". Well,
there must be some compatibility reason, but I haven't run into it.

My workaround requires routinely symlinking the v1 completions into the v2 completions directory. I'm using the script
`sync-homebrew-managed-bash-completions.pl` as needed to do the symlinking, but you need to remember to actually run it
after you install a new Homebrew formula. It's not perfect, but it works.

An added wrinkle to disabling the eager-style loading was created when `bash-completion` v2 made a breaking change in
2.12.0. A lot of work happened between, 2.11 and 2.12.0 including removing many functions of the bash-completion API
like [`_get_comp_words_by_ref`](https://github.com/scop/bash-completion/commit/a9fb23207cbc66302a4500c0eec53fbd6c095377#diff-a4757074ff650000804fd3eaabe9b0a9e02e33040ca5b8afd4c0275fc5f3e136L532).
Thankfully, a compatibility layer was also added in 2.12.0 that adds back the removed functions in a script called [`000_bash_completion_compat.bash`](https://github.com/scop/bash-completion/blob/27a0ef80a2dbd84d8a0d2f90945cc66577149726/bash_completion.d/000_bash_completion_compat.bash).
This script is installed into the eager-style directory, but we are disabling eager loading, and so we need to source it
another way. My idea is to opt-out of the configuration file hook (`/opt/homebrew/etc/profile.d/bash_completion.sh`) and
instead wire up `bash-completion` by hand. This way I can control the order of sourcing and ensure that the compatibility
script is sourced eagerly.

