# Generate completions for a command line string.
#
# In a normal completion context, a user is interactively typing commands in the shell, hitting 'TAB' for completions,
# executing commands, and repeating this flow. In that flow, the 'bash-completion' library lazily loads completion
# functions for commands and these functions stay loaded. This script is different because it's not interactive. It's
# designed to load and run a completion function just once, generate completions, and then exit. We can say this is a
# "one shot" completion flow.
#
# This script is adapted from my other code: https://github.com/dgroomes/bash-playground/blob/407f721f6d00700d353747f6c865c173da6aaab5/completion/bash-completion-example-non-interactive.sh
#
# This script is designed to be called from Nushell as an "external completer" (https://www.nushell.sh/cookbook/external_completers.html).


# Load the 'bash-completion' library. On my system, it's installed via Homebrew.
_one_shot_bash_completion__source() {
    if [[ ! -d "/opt/homebrew/Cellar/bash-completion@2" ]]; then
        >&2 echo "No bash-completion@2 installation found."
        exit 1
    fi

    versioned_installations=(/opt/homebrew/Cellar/bash-completion@2/*)
    if [ ${#versioned_installations[@]} -gt 1 ]; then
        >&2 echo "Multiple bash-completion@2 versions found in Homebrew directory. Please remove all but one. Completions will not be loaded."
        exit 1
    fi

    # This makes it so that 'bash-completion' will find 'completions/_describe-color' in its "lookup path" when it is
    # trying to load the completion script for 'describe-color'.
    export BASH_COMPLETION_USER_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

    . "${versioned_installations[0]}/share/bash-completion/bash_completion"
    . "${versioned_installations[0]}/etc/bash_completion.d/000_bash_completion_compat.bash"
}

# The one and only argument to the script should be a "command line" string. This string is characterized as a partial
# command for which the author wants to see valid completions. For example:
#
#   Command Line        Description
#   ============        ===========
#   "git switch "       The user wants to see Git branches that can be switched to.
#   "docker run --"     The user wants to see valid flags that can be passed to the 'docker run' command.
#   "rustup "           The user doesn't even know where to start. Show all completions for the 'rustup' command.
#
# This function parses the command line string into an array. This function sets the following global variables:
#
#   COMP_LINE: The command line string.
#   COMP_WORDS: An array of words in the command line string.
#
_one_shot_bash_completion__parse_line() {
    if [[ "$#" -ne 1 ]]; then
        >&2 echo "Usage:  $(basename "$0") <command-line>"
        exit 1
    fi
    COMP_LINE="$1"

    # The 'bash-completion' library provides a convenient function for splitting the command line string into an array
    _comp_split COMP_WORDS "$COMP_LINE" || exit 1

    # When there is whitespace at the end of the line, we know that the user is trying to complete a new word, not
    # complete the current word. We must model this new word as an empty string.
    if [[ "$COMP_LINE" =~ [[:space:]]$ ]]; then
        COMP_WORDS+=("")
    fi
}

_one_shot_bash_completion__run() {
    local command
    local comp_spec_line
    local -a comp_spec_array

    command="${COMP_WORDS[0]}"

    # Trigger the 'bash-completion' machinery to find and load a completion function for the command.
    #
    # A 124 exit code means success for this function. The Bash programmable completion docs have a note about the 124
    # convention: https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion.html
    _comp_complete_load "$command"
    if [[ $? -ne 124 ]]; then
        >&2 echo "Command '$command' has no completion function."
        exit 0
    fi

    # Find the "comp spec" (completion specification). This describes the completion rules and completion function
    # for the command. For example:
    #
    #   Command   Comp Spec
    #   =======   ========================
    #   docker    complete -F _docker docker
    #   tar       complete -F _comp_cmd_tar__posix tar
    #   git       complete -o bashdefault -o default -o nospace -F __git_wrap__git_main git
    #
    comp_spec_line=$(complete -p "$command" 2> /dev/null) || {
        # This is unexpected because we should have already bailed if the _comp_complete_load function appeared to not
        # load a completion function.
        >&2 echo "No completion function found for command: '$command'"
        exit 1
    }

    _comp_split comp_spec_array "$comp_spec_line" || exit 1

    # Parse the completion function out of the comp spec. The completion function is given by the '-F' flag.
    for ((i=0; i<((${#comp_spec_array[@]} - 1)); i++)); do
        if [[ "${comp_spec_array[$i]}" == "-F" ]]; then
            completion_function="${comp_spec_array[$((i + 1))]}"
            break
        fi
    done

    if [[ -z $completion_function ]]; then
        >&2 echo "Completion function could not be parsed from the comp spec for command '$command'. Comp spec: '$comp_spec_line'. This is unexpected."
        exit 1
    fi

    COMP_POINT=${#COMP_LINE}
    COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))

    $completion_function

    for completion in "${COMPREPLY[@]}"; do
        echo "$completion"
    done
}

_one_shot_bash_completion__source
_one_shot_bash_completion__parse_line "$@"
_one_shot_bash_completion__run
