#!/opt/homebrew/bin/bash
#
# Use Bash to initialize the environment (i.e. environment variables) and then launch Nushell.
# This script is designed to be used as a login shell. I don't exactly know what I should do about detecting if we're in
# an interactive shell or not, and therefore to source '.bashrc' or not. I'll figure it out.
#
# Because I want to use this as a login shell, we have no PATH, so the shebang needs to hardcode the location of the
# Homebrew-installed Bash. Alternatively, I could script out some checks with useful error messaging, but then that
# would be Bash > Bash > Nushell which is getting silly.

if [ -f "$HOME/.bash_profile" ]; then
  . "$HOME"/.bash_profile
fi

if which nu &> /dev/null; then
  exec nu
else
  echo "Nushell ('nu') was not found on the PATH. Staying in Bash as a fallback."
fi

