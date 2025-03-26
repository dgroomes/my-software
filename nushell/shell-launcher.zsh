#!/bin/zsh
#
# WARNING: This is not used. I have ejected from this. I don't think it's worth my while to mess with the login shell flow as much as
# this. I've flip flopped on this subject. I've just now learned about the convention of adding "-" to the beginning of
# the shell name to indicate that it is a login shell. This is yet another quirky behavior that I don't want to have to
# code around or think about. Similarly, I'm not sure it's wise to use Nushell as a login shell. The most I'll do is
# change the default shell to Homebrew-installed bash.
#
# A "login shell launcher". This script is designed to be configured as the login shell using 'chsh'. It's a shim for
# launching the actual desirable shell. My "actual desirable shell" story is kind of complicated. These are three shells
# in the mix:
#
#     1. Zsh - for bootstrapping and fallback
#     2. Nushell - my "daily driver"
#     3. Bash - for POSIX use cases and shell completions
#
# Zsh is a foundational shell because it is the default pre-installed shell on macOS. Because of this, we need this
# shell for bootstrapping and we can rely on it as a dependable fallback - we know a modern version of it will always
# be available at '/bin/zsh'.
#
# Nushell is my primary shell. I use it as my "daily driver" The configuration surrounding this shell is the most
# fleshed out. Launching Nushell needs to be in a "fast flow". Because of this, I'd like to minimize the bootstrapping
# duration to get into Nushell. Right now, the bootstrap phase is too long: Zsh (shell-launcher.zsh) -> Bash -> Nushell.
# I might even re-write this launcher into Rust/Go so that it is even faster. But I think it would only be a couple
# milliseconds faster, so why bother.
#
# Bash is my secondary shell. I rely on it for many shell completions defined with the 'bash-completion' library and I
# need this shell to do POSIX-y things. It is *very* common that I need to do POSIX-y things and Nushell is not a POSIX
# shell. While I could use Zsh for the same purpose, I prefer to use Bash. It's important to note that macOS comes with
# a very old version of Bash (3.x) and we have no desire to use that. We instead rely on a Homebrew-installed version of
# Bash (5.x). Because Bash is a secondary shell, it's ok for its bootstrapping to be a little slower. I want to bootstrap
# Bash from Nushell so that it picks up all the environment variables that Nushell has set.
#

set -u

# If the logging file is present, this is a signal that logging is desired.
LOG_FILE="$HOME/.shell-launcher.log"
if [ -f "$LOG_FILE" ]; then
    LOG_ENABLED=true
else
    LOG_ENABLED=false
fi

log() {
    [[ $LOG_ENABLED == true ]] || return

    {
      print -n -P "%D{%Y-%m-%d %H:%M:%S} "
      print "$@"
    } >> "$LOG_FILE"
}

log "Program name: $0"
log "Arguments count: $#"
log "Arguments:" "$@"
for arg in "$@"; do
  log "Argument: $arg"
done
log "PID: $$"
PARENT_CMD="$(ps -p $PPID -o comm=)"
log "Parent command: $PARENT_CMD"

# My regular machine configuration will have both Homebrew-installed Nushell and Homebrew-installed Bash. If either of
# these are not present, let's bail immediately and just fall back to Zsh. It is not worth implementing any more
# sophistication than this simple fallback.
#
# It's important to have this fallback because I can imagine a scenario where I've uninstalled Nushell or Bash, I'm
# having an issue with Homebrew, or I'm just reworking my environment. I don't want to be stuck in a position where
# I can't launch a shell because my login shell is broken. What do you even do in that case? Restart in safe mode?
[[ -x "/opt/homebrew/bin/nu" ]] || {
    log "Homebrew-installed Nushell not found. This is irregular. Falling back to Zsh."
    exec /bin/zsh "$@"
}

[[ -x "/opt/homebrew/bin/bash" ]] || {
    log "Homebrew-installed Bash not found. This is irregular. Falling back to Zsh."
    exec /bin/zsh "$@"
}

# We need to do something special to accommodate VSCode/Cursor. Because VSCode can be launched outside of a commandline
# context, like from Spotlight, it doesn't know about any of the environment variables you have likely set up in your
# shell configuration files like .bash_profile and .bashrc. VSCode cleverly works around this problem by executing the
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
[[ "$PARENT_CMD" == /Applications/Cursor.app/Contents/MacOS/Cursor || "$PARENT_CMD" == *"Visual Studio Code"* || "${FORCE_BASH_FLOW:-false}" == true ]] && {
    log "Bootstrapping from Zsh to Nushell to Bash"

    # WARNING: I can't remember if this worked or not, but I've ejected from this launcher script anyway. I'm committing
    # this for posterity and will delete later.
    #
    # This is some particularly dense scripting. We need to do acrobatics to get the environment bootstrapping we want.
    #
    # Drop from the current Zsh process into a Nushell process. This has the effect of doing Nushell's typical
    # initialization and loading all my environment variables. With that done, we drop into a Bash process, which is
    # what VSCode/Cursor are looking for. In particular, VSCode/Cursor sends a command that invokes their own
    # Electron bundle as a way to run a JavaScript snippet that prints environment variables in JSON format.
    exec /opt/homebrew/bin/nu --login <(cat <<-'EOF'
export def --wrapped main [...args] {
    let lf = "~/.shell-launcher.log" | path expand
    if ($lf | path exists) {
      $"Nushell to Bash launcher received ($args | length) arguments:\n($args)\n" | save --append $lf
    }
    exec /opt/homebrew/bin/bash ...$args
}
EOF
) "$@"
}

log "Launching Nushell"
exec /opt/homebrew/bin/nu --login "$@"
