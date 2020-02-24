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
alias gcmp="git checkout master && git pull"
alias ll="ls -lahF"

# SDKMAN aliases to quickly switch between different "candidates" of Java, Gradle, etc.
alias java8="sdk use java 8.0.222.hs-adpt"
alias java13="sdk use java 13.0.2.hs-adpt"
alias java11="sdk use java 11.0.5.hs-adpt"
alias java14="sdk use java 14.ea.28-open"
alias javaGraal="sdk use java 19.3.1.r11-grl"
alias gradle4="sdk use gradle 4.10.3"
alias gradle6="sdk use gradle 6.0.1"