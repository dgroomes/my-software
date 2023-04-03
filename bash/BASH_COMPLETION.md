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


## bash-completion v1

The `bash-completion` project has been around for many years and lived as a 'v1' for a long time. While, you should
mostly only need to use 'v2' in the year 2023, you can benefit from knowing about both versions. It's especially important
that you can learn to identify if information you see online about `bash-completion` is referring to 'v1' or 'v2'. It
won't be obvious, and if you can't tell the difference then you might get yourself more confused (I find myself in a
perpetually confused state with the ecosystem of shell completion).

Related:

* [bash-completion v1 HomeBrew formula](https://github.com/Homebrew/homebrew-core/blob/master/Formula/bash-completion.rb)
* [Discussion about the tension and conflict between bash-completion v1 and v2 in HomeBew](https://discourse.brew.sh/t/bash-completion-2-vs-brews-auto-installed-bash-completions/2391/2)


### bash-completion v2

<https://github.com/Homebrew/homebrew-core/blob/master/Formula/bash-completion@2.rb>

v2 is the new version. It contains a large amount of built-in completions for a diverse set of programs like `chmod`, 
`7z`, `jq` `kill`, `ssh`, `curl`, `java`. See the full list at <https://github.com/scop/bash-completion/tree/master/completions>.

The relevant files/directories are: 

* `/usr/local/etc/profile.d/bash_completion.sh`. This gets sourced from `.bash_profile`. It symlinks to `../../Cellar/bash-completion@2/2.11/etc/profile.d/bash_completion.sh`
* `/usr/local/Cellar/bash-completion@2/2.11/etc/profile.d/bash_completion.sh` This is the configuration file hook. It 
  loads bash-completion.
* `/usr/local/Cellar/bash-completion@2/2.11/share/bash-completion/bash_completion` This is the bash-completion 
  program itself
* `/usr/local/share/bash-completion/bash_completion` this symlinks to the bash-completion program (`/usr/local/Cellar/bash-completion@2/2.11/share/bash-completion/bash_completion`)

The environment variable `BASH_COMPLETION_COMPAT_DIR` is a compatibility option to enable `bash-completion v2` to load
third-party completion scripts that were designed in the era of `bash-completion v1`. For example, set `BASH_COMPLETION_COMPAT_DIR="/usr/local/etc/bash_completion.d"`
if you want to load those completions. HomeBrew formulas often install completions. But this is a problem...

---
**THE BIG PROBLEM**

Legacy bash-completion v1 completions make for a slow "start up a new shell" experience. This is because the "bash-completion"
program [sources all these completions eagerly](https://github.com/scop/bash-completion/blob/b1d163e99e17bcfbc79ee1b6151d8295307d8bc6/bash_completion#L2634).
The 'docker' completion script, in particular, is slow. It takes roughly 0.5 seconds to source on my machine. This is
actually really annoying because I open new shells all the time, especially by way of Intellij's convenient "run this
Markdown shell snippet in an embedded terminal window" feature, which I use constantly I believe is "the way".

So, I need to disable the v1 completions and routinely copy the v1 completions into the v2 completions directory. I don't
have a great solution for this othe than this big warning section. See my related note in the `bash-completion.bash` file.

---

`$HOME/.local/share/bash-completion/completions/` I think this is where you are supposed to put v2 completions. (Where does
HomeBrew put v2 completions? Are v1 and v2 completions using different feautures? In other words, if someone developed
a sophisticated v1 completion do they have to rewrite it for v2?).
