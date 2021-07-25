# Edit '~/.bashrc' in Sublime Text. Why Sublime Text and not Visual Studio Code? Both are great editors. Sublime Text's
# "time to first meaningful paint" is under 500ms whereas I measured the same operation at 4.5 seconds for VS Code. I'm
# going give Sublime Text 4 a try. It's been years since I used it.
alias eb='subl ~/.bashrc'

# Docker aliases
alias dcl="docker container ls"
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

# It's a common convention to create an alias named "ll" to execute the long-hand options in "ls", often "ls -ls".
# Let's use "exa" (https://github.com/ogham/exa) instead.
alias ll="exa -la"
