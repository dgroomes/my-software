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
alias ll="exa -la"

# Run the markdownlint-cli tool (https://github.com/igorshubovych/markdownlint-cli) against a file or files. The file(s)
# must be given as an argument after the alias.
alias mdlint="markdownlint --config ~/repos/personal/my-config/markdownlint/.markdownlint-cli.yml --rules lint-rules"
