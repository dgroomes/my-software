# This script should be executed and the output should be evaluated ('eval') by your .bashrc.
# This script is designed to be pre-bundled by 'bb'.
#
# This file does configuration and initialization work related to Atuin. Atuin requires Bash-Preexec, which also needs
# special shell initialization.

if [[ ! -f ~/.local/lib/bash-preexec/bash-preexec.sh ]]; then
  echo >&2 "Bash-Preexec not found at '~/.local/lib/bash-preexec/bash-preexec.sh'. It will not be bundled."
  return
fi

cat ~/.local/lib/bash-preexec/bash-preexec.sh

if ! command -v atuin &>/dev/null; then
  echo >&2 "'atuin' not found. It will not be bundled."
fi

# Note: I would prefer to keep the normal up arrow behavior. One key to give me the last command, ready to be run or
# edited, can't be beat.
atuin init bash --disable-up-arrow

cat << EOF
# Constrain Bash's history to the bare minimum needed for Atuin to function properly. Atuin's ability to capture the
# previously executed command into history is actually a feature of Bash-Preexec, which itself just uses the shell's
# in-memory history mechanism. Atuin will capture new commands into history as they are executed, so we only need
# HISTSIZE to equal 1. We don't have any need for the shell command history file, because Atuin's history is stored in
# a SQLite file. We set HISTFILESIZE to 0 to disable the history file.
#
# By eliminating the history file, we also workaround an unfortunate behavior of Bash-Preexec which is that it doesn't
# respect your preference for preventing white-space prefixed commands from being saved to history (HISTCONTROL).
# See this related GitHub issue: https://github.com/rcaloras/bash-preexec/issues/115
export HISTSIZE=1
export HISTFILESIZE=0
EOF
