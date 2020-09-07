# Edit '~/.bashrc' in Visual Studio Code
alias eb='code ~/.bashrc'

# Docker aliases
alias dcl="docker container ls"
alias dcu="docker-compuse up --detach"
alias dcuv="docker-compose up --detach --renew-anon-volumes"
alias dcd="docker-compose down --remove-orphans"

# Misc aliases
alias psql_local='psql --username postgres --host localhost'
## Copy the last command into the clipboard. Executes the 'fc' command in a subshell to remove the trailing newline
alias cplastcmd='echo -n $(fc -ln -1 -1) | pbcopy'
## Convert YAML to JSON. Either pipe a YAML file to this command or give it as an argument.
alias yaml2json="ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))'"
## Convert JSON to YAML. Either pipe a JSON file to this command or give it as an argument.
alias json2yaml="ruby -ryaml -rjson -e 'puts YAML.dump(JSON.load(ARGF))'"
alias gcmp="git checkout main && git pull"
alias ll="ls -lahF"
