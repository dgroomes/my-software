# Docker aliases
alias dcl="docker container ls"
# This is what I'll call a "hard restart" version of the "up" command. It forces the containers to be created fresh
# instead of being reused and it does the same for anonymous volumes. This is very convenient for the development process
# where you frequently want to throw everything away and start with a clean slate. I use this for stateful workloads like
# Postgres and Kafka.
alias dcuf="docker-compose up --detach --force-recreate --renew-anon-volumes"
alias dcd="docker-compose down --remove-orphans"

# Misc aliases
alias psql_local='psql --username postgres --host localhost'
## Copy the last command into the clipboard. Executes the 'fc' command in a subshell to remove the trailing newline
alias cplastcmd='echo -n $(fc -ln -1 -1) | pbcopy'
alias gcmp="git checkout main && git pull"

# It's a common convention to create an alias named "ll" to execute the long-hand options in "ls", often "ls -ls".
# Let's use "exa" (https://github.com/ogham/exa) instead.
alias ll="exa --long --git --git-ignore --icons"
# Similarly, "la" is a convention for listing "all" files which will show dot files.
alias la="exa --long --git --all --icons"
# 't' for tree. Limit the maximum depth
alias lt="exa --tree --git --git-ignore --icons --level 2"
# Full tree. Include everything and no limits on depth.
alias tree="exa --tree --git-ignore --icons"

# Run the markdownlint-cli2 tool (https://github.com/DavidAnson/markdownlint-cli2) using my custom rules. The glob
# pattern must be given as an argument after the alias.
alias mdlint="markdownlint-cli2-config ~/repos/personal/my-config/markdownlint/.markdownlint-cli2.jsonc"

# Use ripgrep to find files
# See https://github.com/BurntSushi/ripgrep/issues/193#issuecomment-513201558
alias rgf='rg --files | rg'
