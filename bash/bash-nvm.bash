# This file should be sourced by .bash_profile or .bashrc.
#
# This file does configuration and initialization work related to the 'nvm' (Node Version Manager) software package.
# Note 2023-04-02: This is the single slowest thing among all Bash code that get sourced (".") at Bash shell startup
# time. It takes roughly 150ms. The total time across scripts is roughly 300ms. The nvm bash completion script isn't so
# slow, it's the nvm.sh script itself. Is there any way to lower the impact of this slowness on the overall Bash startup
# time?
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
