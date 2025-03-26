# The strategy of this .bash_profile is to do a minimum amount of its own environment environmental setup, and instead
# to delegate to Nushell to provide the lion's share of environment variables.
#
# This is consistent with my "Nushell is primary, Bash is secondary" preference.
#
# I might consider making this script more defensive by doing extra checks like in the extreme case where
# "HOME" is not defined. I really want this script to gracefully fail if something goes wrong because it's my login
# shell and I need a shell to fix the shell if you know what I mean.

# If the logging file is present, this is a signal that logging is desired.
#
# This convention has been really helpful for me to debug the initialization and flow of the login shell, and shells in
# general. I like how simple it is too.
_bash_profile_log_file="$HOME/.shell-debug.log"
if [[ -f "$_bash_profile_log_file" ]]; then
    _bash_profile_log_enabled=true
else
    _bash_profile_log_enabled=false
fi

_bash_profile_log() {
    [[ "$_bash_profile_log_enabled" = true ]] || return

    {
      echo -n "[.bash_profile] "
      date "+%H:%M:%S" | tr -d "\n"
      echo " $1"
    } >> "$_bash_profile_log_file"
}

_bash_profile_log "Program name: $0"
_bash_profile_parent_cmd="$(ps -p $PPID -o comm=)"
_bash_profile_log "Parent command: $_bash_profile_parent_cmd"
_bash_profile_log "PID: $$"
_bash_profile_log "Arguments count: $#"
for arg in "$@"; do
  _bash_profile_log "Argument: $arg"
done

_bash_profile_bash_completion() {
    export BASH_COMPLETION_COMPAT_DIR="/disable-legacy-bash-completions-by-pointing-to-a-dir-that-does-not-exist"

    local dir="/opt/homebrew/opt/bash-completion@2/"

    if [[ -d $dir ]]; then
        . "${dir}/share/bash-completion/bash_completion"
        . "${dir}/etc/bash_completion.d/000_bash_completion_compat.bash"
    else
        echo >&2 "(error) bash-completion not loaded."
    fi
}

# Delegate to Nushell for a source of environment variables and then declare them in the Bash shell session.
#
# This is a particularly fragile thing to do, but I've done my best to boil down its essential complexity, keep it
# robust, and keep it legible.
#
# My Nushell setup is elaborate and defines important environment variables like the PATH, and variables related
# to things like Homebrew and the JDK. Importantly, this list keeps growing. I want a way to get the goodies of these
# environment variables into my Bash shell session. Here is an abbreviated example of environment variables in a Nushell
# session of mine:
#
#     HOME                       /Users/davidgroomes
#     HOMEBREW_CELLAR            /opt/homebrew/Cellar
#     JAVA_HOME                  /opt/homebrew/opt/my-open-jdk@21/libexec/Contents/Home
#     MANPATH                    :/Applications/Ghostty.app/Contents/Resources/ghostty/../man
#     NU_VERSION                 0.103.0
#                                ╭────┬──────────────────────────────────────╮
#     PATH                       │  0 │ /Users/davidgroomes/.local/bin       │
#                                │  2 │ /opt/homebrew/opt/my-open-jdk@21/bin │
#                                │  3 │ /opt/homebrew/bin                    │
#                                ╰────┴──────────────────────────────────────╯
#     PROMPT_COMMAND             closure_868
#     PROMPT_COMMAND_RIGHT       closure_873
#     PROMPT_INDICATOR
#     PROMPT_INDICATOR_VI_INSERT :
#     PROMPT_INDICATOR_VI_NORMAL >
#     PROMPT_MULTILINE_INDICATOR ∙
#     PWD                        /Users/davidgroomes/
#     SHELL                      /opt/homebrew/bin/bash
#
# Some of these variables are not portable into Bash and wouldn't make sense, like the PROMPT_COMMAND closure (Nushell
# function). Some might lead to undefined behavior if ported into the Bash session, like PWD and HOME (I would much
# rather let the shell manage these). Some of these variables are not useful to me in Bash, but are not too dangerous to
# port over, like NU_VERSION. Many of the variables we absolutely want to port over, like PATH, JAVA_HOME, and
# HOMEBREW_CELLAR.
#
# One way you could provision a Bash session with all these environment variables is to actually start with a Nushell
# session and 'exec' into a Bash process image. This is nice, because the environment variables will be automatically
# inherited. I like this approach in general, but I've run into pressure when I actually toy with that setup, especially
# when dealing with the machinery around login shells. I've had a custom "login shell launcher" which is itself just a
# POSIX script that then execs Nushell and then execs Bash (or execs Bash and then execs Nushell). But it turns out that
# there are other edge cases with login shells, like keying off a leading "-" in the process name. Similarly, software
# like VSCode, will key off of the name of the login shell process and go through different code flows. It's
# complicated and mired in historical baggage.
#
# I've decided I'm not going to mess with the login shell flow.
#
# Instead, I'll use this function to run Nushell, print out a filtered set of environment variables in a structured
# way, and then incorporate them into the Bash shell session with 'export' commands.
#
# Here is a list of concepts, requirements, design decisions, and constraints (especially for an LLM to adhere to):
#
#  * The Bash shell instance is referred to as BMS, short for "Bash main shell"
#  * The Nushell shell instance is referred to as NES, short for "Nushell external shell"
#  * Env vars already defined in BMS will not be overridden by NES env vars except for PATH
#  * NES will filter for only env vars of these simple Nushell types: string, int, bool (and an exception for PATH which is list<string>)
#  * The PATH variable in NES will be transformed according to the typical conversion rule for PATH defined by Nushell.
#    Relatedly, see the docs on "Environment Variable Conversions" and "ENV_CONVERSIONS": https://www.nushell.sh/book/environment.html#environment-variable-conversions
#  * The env vars will be serialized from NES to BES in a line-based fashion
#  * The first line is the name of the first env var
#  * The second line is the base64-encoded value of the first env var
#  * This pattern repeats for each env var ported from NES. An env var with an empty value still produces a value line.
#  * BMS will stick as much as possible to Bash built-ins and idiomatic Bash.
#  * (NOT IMPLEMENTED) NES will filter for only env vars whose name is alphanumeric or underscore. Because I'm not
#    base64 encoding the variable names, I want a safeguard so that the line-based serialization doesn't get messed up.
#    It *is* possible to define Nushell env vars with newlines.
#  * eval will not be used
#  * The Nushell code will be expressed as a big string. I don't want to distribute a separate script file.
#  * Env var names will be logged as they are imported by BMS using the _bash_profile_log function
#  * Env var values will never be logged.
#  * The exit code of NES must be checked for success
#
_bash_profile_source_nushell_env() {
    [[ ! -x "/opt/homebrew/bin/nu" ]] && {
        >&2 echo "(error) 'nu' not found in the Homebrew location. Can't source environment variables from Nushell."
        return
    }

    local nes_out

    # Note: I need both '--login' and '--interactive' to make the right configuration flows happen. I dont' want to
    # think about why.
    nes_out=$(/opt/homebrew/bin/nu --login --interactive --commands '
def filter-and-encode [name value] {
    let v = if ($name == PATH) {
        $value | path-to-string
    } else if (($value | describe) in [string int bool]) {
        $value | to text
    } else {
        return null
    }

    let vb64 = $v | encode base64

    [$name $vb64]
}

def path-to-string [] {
    path expand --no-symlink | str join (char esep)
}

$env | transpose name value | each { filter-and-encode $in.name $in.value } | flatten | str join $"\n"
')

    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        >&2 echo "(error) Nushell environment capturing failed with exit code $exit_code"
        return
    fi

    while read -r var_name && read -r var_b64; do
        local var_val
        var_val="$(printf '%s' "$var_b64" | base64 --decode)"

        if [[ -v $var_name && "$var_name" != "PATH" ]]; then
            _bash_profile_log "Skipping '$var_name' because it is already set."
            continue
        fi

        _bash_profile_log "Porting '$var_name'"
        export "$var_name=$var_val"
    done <<< "$nes_out"
}

_bash_profile_init() {
    # I'm using this check as a precaution against the unlikely, but possible, scenario where I've mistakenly created some
    # recursive loop like Nushell invoking Bash, and Bash invoking Nushell, etc. Or `.bash_profile` invoking `.bashrc` and
    # vice versa.
    [[ "${BASH_PROFILE_DID_INIT:-}" = true ]] && {
      echo >&2 "(error) Already initialized."
      return
    }

    export BASH_PROFILE_DID_INIT=true

    _bash_profile_bash_completion
    _bash_profile_source_nushell_env
}

_bash_profile_init
