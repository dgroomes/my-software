# This script should be executed and the output should be evaluated ('eval') by your .bashrc.
# This script is designed to be pre-bundled by 'bb'.
#
# This file does configuration and initialization work related to Homebrew.
#
# Caution: the exact incantation of shell code here is specific to the Apple Silicon-based Homebrew.
#
# Tip: you can tell if Homebrew is the Intel-based one if you see that it's installed at `/usr/local`. It is the Apple
# Silicon-based Homebrew if it's installed at `/opt/homebrew`.

/opt/homebrew/bin/brew shellenv
