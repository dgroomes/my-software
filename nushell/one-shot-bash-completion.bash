#!/usr/bin/env bash --noprofile
# Generate completions for a command line string based on completion definitions authored using the 'bash-completion'
# library.
#
# In a normal completion context, a user is interactively typing commands in the shell, hitting 'TAB' for completions,
# executing commands, and repeating this flow. In that flow, the 'bash-completion' library lazily loads completion
# functions for commands and these functions stay loaded. This script is different because it's not interactive. It's
# designed to load and run a completion function just once, generate completions, and then exit. We can say this is a
# "one shot" completion flow.
#
# This script is adapted from my other code: https://github.com/dgroomes/bash-playground/blob/407f721f6d00700d353747f6c865c173da6aaab5/completion/bash-completion-example-non-interactive.sh
#
# This script is designed to be called from Nushell as part of an "external completer" (https://www.nushell.sh/cookbook/external_completers.html).
#
# This script requires that the 'bash-completion' library (v2) is installed and pointed to by the 'BASH_COMPLETION_INSTALLATION_DIR'
# environment variable.
#
# Here are some examples of calling this script, where 'bash-completion' is installed via Homebrew:
#
#     Command:
#         BASH_COMPLETION_INSTALLATION_DIR=/opt/homebrew/opt/bash-completion@2 ./one-shot-bash-completion.bash "7z "
#     Yields:
#         a
#         b
#         d
#         (The rest is omitted for brevity)
#
#     Command:
#         BASH_COMPLETION_INSTALLATION_DIR=/opt/homebrew/opt/bash-completion@2 ./one-shot-bash-completion.bash "git c"
#     Yields:
#         checkout
#         cherry-pick
#         citool
#         (The rest is omitted for brevity)
#
#     Command:
#         BASH_COMPLETION_INSTALLATION_DIR=/opt/homebrew/opt/bash-completion@2 ./one-shot-bash-completion.bash "cat "
#     Yields:
#         (exit code 127, which indicates no completion definition was found for the command)
#
# I recommend being even more explicit than setting just the 'BASH_COMPLETION_INSTALLATION_DIR' environment variable.
# The 'bash-completion' library controls its behavior by a few other variables and I've found myself getting turned
# around as I learned (and re-learned) 'bash-completion'. Explicitly acknowledging and reviewing these variables
# keeps you in control. Here is an example invocation from a Nushell command line:
#
#     with-env {
#         BASH_COMPLETION_INSTALLATION_DIR: /opt/homebrew/opt/bash-completion@2
#         BASH_COMPLETION_USER_DIR: ([$env.HOME .local/share/bash-completion] | path join)
#         BASH_COMPLETION_COMPAT_DIR: /disable-legacy-bash-completions-by-pointing-to-a-dir-that-does-not-exist
#     } { ./one-shot-bash-completion.bash "7z " }
#
# In particular, the 'BASH_COMPLETION_USER_DIR' controls where 'bash-completion' looks for user-defined completion
# scripts. The 'bash-completion' distribution comes with completion scripts for many standard command line
# tools like 7z, lsof, rsync, and more. All other scripts are considered user-defined. Very rich command line tools like
# "git" and "docker" are not distributed with 'bash-completion' and so we must install these separately and make
# 'bash-completion' aware of their location.
#
# The 'BASH_COMPLETION_COMPAT_DIR' also helps us disable the eager-style loading of completion scripts. The v1 era of
# 'bash-completion' only supported eager-style loading (I think), but we are using 'bash-completion' v2 and have no
# interest in wasting time loading all completions scripts. We can set 'BASH_COMPLETION_COMPAT_DIR' to a non-existent
# directory to effectively disable this behavior.

# Load the 'bash-completion' library.
_one_shot_bash_completion__source() {
    if [ -z "${BASH_COMPLETION_INSTALLATION_DIR:-}" ]; then
        >&2 echo "BASH_COMPLETION_INSTALLATION_DIR is not set. Please set BASH_COMPLETION_INSTALLATION_DIR to the directory where the 'bash-completion' library is installed."
        exit 1
    fi

    if [[ ! -d "$BASH_COMPLETION_INSTALLATION_DIR" ]]; then
        >&2 echo "'$BASH_COMPLETION_INSTALLATION_DIR' is not a directory. Please set BASH_COMPLETION_INSTALLATION_DIR to the directory where the 'bash-completion' library is installed."
        exit 1
    fi

    . "$BASH_COMPLETION_INSTALLATION_DIR/share/bash-completion/bash_completion"
    . "$BASH_COMPLETION_INSTALLATION_DIR/etc/bash_completion.d/000_bash_completion_compat.bash"
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
    _comp_load "$command" || {
        >&2 echo "Command '$command' has no completion function."

        # Exit with a 127 to convey that the command has no completion function. 127 is typically used to convey
        # "Command not found". This is a pretty good fit for our need.
        #
        # It's important to let the caller disambiguate between "There is no completion definition for this command"
        # and "There is a completion definition for this command but there are no completion suggestions for the command
        # line string."
        exit 127
    }

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
        >&2 echo "Unexpected. No completion spec found for command '$command' but '_comp_complete' should have already loaded one by this point."
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

    $completion_function $COMP_WORDS

    for completion in "${COMPREPLY[@]}"; do
        echo "$completion"
    done
}

_one_shot_bash_completion__source
_one_shot_bash_completion__parse_line "$@"
_one_shot_bash_completion__run
