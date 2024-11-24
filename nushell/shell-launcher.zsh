#!/usr/bin/env zsh
#
# A "login shell launcher". This script is designed to be configured as the login shell using 'chsh'. It's a shim for
# launching the actual desirable shell.
#
# On macOS, Zsh is installed by default but my preference is to use Nushell. My strategy for launching Nushell is to
# bootstrap it from Bash because I'd like to use Bash as a secondary shell and have it own some of the environmental
# setup. macOS ships an old version of Bash and some day it might stop shipping Bash entirely. Overall, this is a gnarly
# situation. This script is an exercise in bootstrapping.
#
# Essentially, we're bootstrapping from Zsh (macOS) > Bash (Homebrew) > Nushell (Homebrew)

set -u

# If the logging file is present, this is a signal that logging is desired.
LOG_FILE="$HOME/.shell-launcher.log"
if [ -f "$LOG_FILE" ]; then
    LOG_ENABLED=true
else
    LOG_ENABLED=false
fi

log() {
    [[ $LOG_ENABLED == true ]] && print -P "%D{%Y-%m-%d %H:%M:%S} $@" >> "$LOG_FILE"
}

SHELL_ARGS=("$@")
log "Arguments: ${SHELL_ARGS[@]}"

# How do I capture the args in a variable here so that I can call them inside other functions?

exec_bash() {
    if [[ ! -x "/opt/homebrew/bin/bash" ]]; then
        log "Homebrew-installed Bash was not found. Falling back to Zsh"
        exec /usr/bin/env zsh "${SHELL_ARGS[@]}"
    fi

    log "Launching Homebrew-installed Bash"
    exec /opt/homebrew/bin/bash "${SHELL_ARGS[@]}"
}

log "PID: $$"
PARENT_CMD="$(ps -p $PPID -o comm=)"
log "Parent command: $PARENT_CMD"

# We need to do something special to accommodate VSCode/Cursor. Because VSCode can be launched outside of a commandline
# context, like from Spotlight, it doesn't know about any of the environment variables you have likely set up in your
# shell conguration files like .bash_profile and .bashrc. VSCode cleverly works around this problem by executing the
# login shell, printing out the environment variables, and capturing them. Refer to the docs and code:
#
#   - https://github.com/microsoft/vscode/blob/213334eb801247fa2632c9ccf204ecb4f1865db1/src/vs/platform/shell/node/shellEnv.ts#L102
#   - https://code.visualstudio.com/docs/supporting/faq#_resolving-shell-environment-fails
#
# There is actually some code in the linked 'shellEnv.ts' that has some Nushell support but that code path won't work,
# but feel free to try. I'm having trouble with VSCode/Cursor because when it launches, it tries to resolve the shell environment by launching
# a shell (the default shell?): https://code.visualstudio.com/docs/supporting/faq#_resolving-shell-environment-fails
#
# And I get the following:
#
#    Unable to resolve your shell environment: Unexpected exit code from spawned shell (code 1, signal null)
#
# I think VSCode tries to print out the environment variables of this short-lived shell instance, but for I'm sure a few
# reasons, this flow doesn't work with Nushell. I tried debugging with trace logging but that didn't yield anything.
# Let's try to detect if VSCode/Cursor launched the process and then just not launch Nushell.
[[ "$PARENT_CMD" == /Applications/Cursor.app/Contents/MacOS/Cursor ]] && {
    log "Cursor is likely trying to resolve the environment. Staying in Bash for compatibility."
    exec_bash
}

[[ "$PARENT_CMD" == *"Visual Studio Code"* ]] && {
    log "VSCode is likely trying to resolve the environment. Staying in Bash for compatibility."
    exec_bash
}

if [[ ! -x "/opt/homebrew/bin/nu" ]]; then
    log "Nushell not found in Homebrew. Falling back to Bash"
    exec_bash
fi

if [[ ! -x "/opt/homebrew/bin/bash" ]]; then
    log "Bash is a pre-requisite for launching Nushell but Bash was not found in Homebrew. Falling back to Zsh"
    exec /usr/bin/env zsh "${SHELL_ARGS[@]}"
fi

# At this point, I'm going to toss any arguments passed to the launcher because I don't have a way to re-interpret them
# for Nushell. Special cases like the VSCode "resolve environment" case will need custom work.
#
# I'm not attached to this approach. It might be better to do away with this launcher script and instead have my Nushell
# config (config.nu) implement the same "exec Bash and print our JSON formatted environment variables" that VSCode does.
# I don't know.
log "Launching Nushell by way of Bash"
exec /opt/homebrew/bin/bash --login -i -c "exec /opt/homebrew/bin/nu"
