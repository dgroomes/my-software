# Edit '~/.bashrc' in Visual Studio Code
alias eb='code ~/.bashrc'

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
alias ll="ls -lahF"

# Taken from https://github.com/tednaleid/shared-zshrc/blob/e4a9c7b17ba1dc5e708e52d5144b98d3948e8f77/zshrc_base#L337
# Thank you!
jqpath_cmd='
def path_str: [.[] | if (type == "string") then "." + . else "[" + (. | tostring) + "]" end] | add;

  . as $orig |
    paths(scalars) as $paths |
    $paths |
    . as $path |
    $orig |
    [($path | path_str), "\u00a0", (getpath($path) | tostring)] |
    add
'
# pipe json in to use fzf to search through it for jq paths, uses a non-breaking space as an fzf column delimiter
alias jqpath="jq -rc '$jqpath_cmd' | cat <(echo $'PATH\u00a0VALUE') - | column -t -s $'\u00a0' | fzf +s -m --header-lines=1"
