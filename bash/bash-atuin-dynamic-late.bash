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
