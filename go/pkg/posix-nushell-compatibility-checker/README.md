# posix-nushell-compatibility-checker

NOT YET IMPLEMENTED

The `posix-nushell-compatibility-checker` checks if a given POSIX shell is safe to execute in Nushell.


## Overview

This tool supports a niche use-case. Many `README.md` files in software projects will express shell commands to build,
test, and experiment with the project. The variety and volume of useful commands can sometimes be surprising. You can
re-express these commands in helper shell scripts, but I prefer to extract them right out of the Markdown contents. I
use other tools in `my-software` like `markdown-code-fence-reader` and `run-from-readme` to extract these snippets.

The problem is, most of these commands are POSIX shell commands, but I use Nushell. It's not safe to just plop any
given command, like `echo $HOME`, into Nushell because Nushell supports different syntax. I work around this by taking
the original command and safe-escaping it using the `run-from-readme` tool and executing it with `bash`. For example,

```shell
echo $HOME
```

Becomes

```nushell
bash -c (r#'
echo $HOME
'# | str substring 1..-2)
```

But, this translation is not needed for the category of commands that are of the "command plus string args" variety.
For example,

```shell
poetry env use python3.12
```

Does not need to be escaped. It's perfectly safe for Nushell. The `posix-nushell-compatibility-checker` tool checks for
this safety.

The scope of this tool is NOT to do any translation. I only want to support the "command plus string args"" case because
that covers the bulk of cases and for a modest compatibility checking algorithm. 
