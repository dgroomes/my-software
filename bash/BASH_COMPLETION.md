# Bash Completion

Bash completion is a general feature of Bash, but is also conflated with a third-party project of the same name:
<https://github.com/scop/bash-completion>.

Bash completion is more formally known as its "programmable completion" feature. See 
<http://tldp.org/LDP/abs/html/tabexpansion.html>.

`bash-completion` (<https://github.com/scop/bash-completion>) the project describes itself as

> bash-completion is a collection of command line command completions for the Bash shell, collection of helper functions
> to assist in creating new completions, and set of facilities for loading completions on demand as well as installing 
> them.

### bash-completion v1

<https://github.com/Homebrew/homebrew-core/blob/master/Formula/bash-completion.rb>

v1 is the old version. It is still the primarily used version, but you should try to use v2 (see this discussion 
<https://discourse.brew.sh/t/bash-completion-2-vs-brews-auto-installed-bash-completions/2391/2>).


### bash-completion v2

<https://github.com/Homebrew/homebrew-core/blob/master/Formula/bash-completion@2.rb>

v2 is the new version. It contains a large amount of built-in completions for a diverse set of programs like `chmod`, 
`7z`, `jq` `kill`, `ssh`, `curl`, `java`. See the full list at <https://github.com/scop/bash-completion/tree/master/completions>.

The relevant files are: 

* `/usr/local/etc/profile.d/bash_completion.sh`. This gets called from `.bash_profile`. It symlinks to `../../Cellar/bash-completion@2/2.10/etc/profile.d/bash_completion.sh`
* `/usr/local/Cellar/bash-completion@2/2.10/etc/profile.d/bash_completion.sh` This is the configuration file hook. It 
  loads bash-completion.
* `/usr/local/Cellar/bash-completion@2/2.10/share/bash-completion/bash_completion` This is the bash-configuration 
  program itself
* `/usr/local/share/bash-completion/bash_completion` what is this? What is the point? Its contents are identical to
  `/usr/local/Cellar/bash-completion@2/2.10/share/bash-completion/bash_completion` and it is not a symlink.

The environment variable `BASH_COMPLETION_COMPAT_DIR` is a compatibility option to enable `bash-completion v2` to load
third-party completion scripts that were designed in the era of `bash-completion v1` (at least that's how I understand 
it). For example, set `BASH_COMPLETION_COMPAT_DIR="/usr/local/etc/bash_completion.d"` if you want to load those 
completions. (Where do third-party completion scripts go for v2?)
