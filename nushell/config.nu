# I'm still zeroing in on the ideal sourcing strategy. I would prefer the "sourcing from a directory" approach, but this
# is not possible. The Nushell docs point this out: https://www.nushell.sh/book/modules.html#dumping-files-into-directory
source setup/core.nu
source setup/misc.nu
source setup/nu-scripts-sourcer.nu
source setup/starship.nu
source setup/zoxide.nu
source setup/atuin.nu

use lib/file-set.nu *
use lib/lib.nu *
use lib/node.nu *
use lib/open-jdk.nu *
use lib/postgres.nu *
use lib/zdu.nu *

# I don't really understand the essential coverage, or purpose, of the directories added to the PATH by the macOS
# "/usr/libexec/path_helper" tool. But, at the least, I know it adds "/usr/local/bin" to the PATH and I need that.
# I'm not going to dig into this further. I just vaguely know about /etc/paths and /etc/paths.d and today I learned
# or maybe re-learned about /etc/profile and /etc/bashrc.
$env.PATH = ($env.PATH | append "/usr/local/bin")

$env.config.buffer_editor = "subl"

export alias clc = cp-last-cmd
export alias ll = ls -l
export alias la = ls -a

# Git aliases
export alias gsdp = git-switch-default-pull
export alias gs = git status

# Docker aliases
export alias dcl = docker container ls
## This is what I'll call a "hard restart" version of the "up" command. It forces the containers to be created fresh
## instead of being reused and it does the same for anonymous volumes. This is very convenient for the development process
## where you frequently want to throw everything away and start with a clean slate. I use this for stateful workloads like
## Postgres and Kafka.
export alias dcuf = docker-compose up --detach --force-recreate --renew-anon-volumes
export alias dcd = docker-compose down --remove-orphans

# Miscellaneous aliases
export alias psql_local = psql --username postgres --host localhost

# bash-completer-log
#
# Print debugging is a simple savior.
def bcl [msg: string] {
    $msg | save --append ~/.nushell-bash-completer.log
    (char newline) | save --append ~/.nushell-bash-completer.log
}

# Define an external completer (https://www.nushell.sh/cookbook/external_completers.html) based on Bash and the
# 'bash-completion' library (https://github.com/scop/bash-completion).
let bash_completer =  { |spans|
    let bash_path = which bash | if ($in | is-empty) {
        # Note: you won't see this message when the closure is invoked by Nushell's external completers machinery.
        # Silencing (or "swallowing") the output of a rogue completer is designed as a feature. Totally fair, but that
        # makes debugging external completer closures difficult. See the 'bash-complete' function which is designed to
        # wrap this closure, which let's you see output like this normally. I didn't have any luck with the standard
        # library logger or the internal logs (e.g. `nu --log-level debug`) either.
        print "Bash is not installed. The Bash completer will not be registered."
        return
    } else {
       $in.0.path
    }

    let one_shot_bash_completion_script = [$nu.default-config-dir one-shot-bash-completion.bash] | path join | if ($in | path exists)  {
        $in | path expand
    } else {
        print "The one-shot Bash completion script does not exist. No completions will be available."
        return
    }

    let line = $spans | str join " "

    # We set up a controlled environment so we have a better chance to debug completion problems. In particular, we are
    # exercising control over the "search order" that 'bash-completion' uses to find completion definitions. For more
    # context, see this section of the 'bash-completion' README: https://github.com/scop/bash-completion/blob/07605cb3e0a3aca8963401c8f7a8e7ee42dbc399/README.md?plain=1#L333
    mut env_vars = {
        BASH_COMPLETION_INSTALLATION_DIR: /opt/homebrew/opt/bash-completion@2
        BASH_COMPLETION_USER_DIR: ([$env.HOME .local/share/bash-completion] | path join)
        BASH_COMPLETION_COMPAT_DIR: /disable-legacy-bash-completions-by-pointing-to-a-dir-that-does-not-exist
        XDG_DATA_DIRS: /opt/homebrew/share
    }

    mut env_vars_path = []

    # Homebrew's 'brew' command comes with an odd implementation of its completion scripts. It relies on the
    # "HOMEBREW_" environment variables that are set up in the 'brew shellenv' command. See https://github.com/Homebrew/brew/blob/e2b2582151d451d078e9df35a23eef00f4d308b3/completions/bash/brew#L111
    # And it relies on grep.
    #
    # So, let's pass the 'HOMEBREW_REPOSITORY' environment variable through and let's make sure 'grep' is on the PATH.
    if ($env.HOMEBREW_REPOSITORY? | is-not-empty) {
        $env_vars = $env_vars | insert HOMEBREW_REPOSITORY $env.HOMEBREW_REPOSITORY
    }

    $env_vars_path = ($env_vars_path | append (which grep | $in.0?.path | path dirname))

    # Homebrew's completion for things like "brew uninstall " will execute 'brew' so that it can list out your installed
    # packages. 'brew' requires the HOME environment for some reason. If you omit it, you'll get the error message
    # "$HOME must be set to run brew.".
    #
    # Also, and I couldn't debug why, but '/bin' needs to be on the PATH as well. Seems reasonable enough.

    $env_vars = ($env_vars | insert HOME $env.HOME)
    $env_vars_path = ($env_vars_path | append "/bin")

    # In its completion lookup logic, 'bash-completion' considers the full path of the command being completed.
    # For example, if the command is 'pipx', then 'bash-completion' tries to resolve ' pipx' to a location on the PATH
    # by issuing a 'type -P -- pipx' command (https://github.com/scop/bash-completion/blob/07605cb3e0a3aca8963401c8f7a8e7ee42dbc399/bash_completion#L3158).
    # It's rare that this is needed to make completions work, but I found it was needed for 'pipx', at least. Do the
    # 'pipx' completions definitions code to an absolute path? Seems like a strange implementation. I'd be curious to
    # learn more.
    #
    # So, we can't isolate the PATH entirely from the one-shot Bash completion script. Let's create a PATH that just
    # contains the directory of the command being completed.
    $env_vars_path = ($env_vars_path | append ($spans.0? | which $in | get path | path dirname))

    let path = ($env_vars_path | str join ":")
    $env_vars = ($env_vars | insert PATH $path)

    # Turn the environment variables into "KEY=VALUE" strings in preparation for the 'env' command.
    mut env_var_args = $env_vars | items { |key, value| [$key "=" $value] | str join }

#    bcl $"env_var_args: ($env_var_args)"

    # Note: we are using "$bash_path" which is the absolute path to the Bash executable of the Bash that's installed
    # via Homebrew. If we were to instead use "bash", then it would resolve to the "bash" that's installed by macOS
    # which is too old to work with 'bash-completion'.
    let result = env -i ...$env_var_args $bash_path --noprofile $one_shot_bash_completion_script $line | complete

#    bcl $"result: ($result)"

    # The one-shot Bash completion script will exit with a 127 exit code if it found no completion definition for the
    # command. This is a normal case, because of course many commands don't have or need completion definitions. At
    # this point, we can't just return an empty list because that would be interpreted by Nushell as "completion options
    # were found to be empty", and the Nushell command line would show "NO RECORDS FOUND". We don't want that. We want
    # Nushell to fallback to file completion. For example, we want "cat " to show the files and directories in the
    # current directory.
    #
    # Right now (2024-06-21) there is not a way to tell Nushell that no completion definitions were found (see https://github.com/nushell/nushell/issues/6407#issuecomment-1227250012)
    # but we can return unparseable JSON (see the note in https://www.nushell.sh/book/custom_completions.html#custom-descriptions)
    # or we can throw an error. In either case, Nushell's completion machinery will actually catch the error and show
    # the error message in a very fast flash of text on the command line. For example, https://github.com/nushell/nushell/blob/10e84038afe55ba63c9b3187e6d3a1749fa2cc65/crates/nu-cli/src/completions/completer.rs#L115
    # While that's a little awkward, I'm perfectly happy with that. It's so fast you can't even read it (although you'll
    # notice the flash). To limit the size of the flashing text, I'll actually use a short error message.
    if ($result.exit_code == 127) {
        error make --unspanned {
            msg: ("No defs.")
        }
    }

    if ($result.exit_code != 0) {
        error make --unspanned {
            msg: ("Something unexpected happened while running the one-shot Bash completion." + (char newline) + $result.stderr)
        }
    }

    # There are a few data quality problems with the completions produced by the Bash script. It's important to note
    # that the Bash completion functions are able to produce anything they want. I've found that the completions for
    # 'git' return duplicates when I do "git switch ". For example, for a repository that only has one branch ("main"),
    # the completion scripts produce "main" twice. I only see that in my non-interactive flow, and I'm taking a wild
    # guess that Bash has some presentation logic that actually de-duplicates (and sorts?) completions before presenting
    # them to the user. Nushell does not do de-duplication of completions (totally fair).
    #
    # Another problem is the trailing newline produced by the Bash script. In general, you just need to be careful with
    # the characters present in completion suggestions because Nushell seems to just let it fly. So a newline really
    # messes things up.
    #
    # The serialization/deserialization of the generated completions from the Bash process to the Nushell process is a
    # bit naive. Consider unhandled cases.
    $result.stdout | split row (char newline) | where $it != '' | sort | uniq
}

# This function is meant for debugging the external completer closure. See the related note inside the closure.
export def bash-complete [spans: list<string>] {
    do $bash_completer $spans
}

$env.config.completions.external = {
  enable: true
  completer: $bash_completer
}

export alias cdr = cd-repo
export alias rfr = run-from-readme

activate-defaults

# Discover keg installations of OpenJDK and make them available (i.e. "advertise") as version-specific "JAVA_HOME"
# environment variables.
#
# For example, for a Java 17 OpenJDK keg installed at "/opt/homebrew/opt/my-open-jdk@17" then set the environment
# variable "JAVA_HOME_17" to that path.
def --env advertise-installed-open-jdks [] -> nothing {
    for keg in (my-open-jdk-kegs) {
        let java_x_home = $"JAVA_($keg.java_version)_HOME"
        load-env { $java_x_home: $keg.jdk_home_dir }
    }
}

advertise-installed-open-jdks

const ACTIVATE_DO = r#'
# ERASE ME
overlay use --prefix do.nu
let hooks = $env.config.hooks.pre_prompt
let filtered = $hooks | where ($it | describe) != "string" or $it !~ "# ERASE ME"
$env.config.hooks.pre_prompt = $filtered
'#

# Activate a 'do.nu' script as an overlay module.
#
# By convention, I put 'do.nu' scripts in projects and this lets me compress my workflow. The 'do activate' command
# activates the local 'do.nu' script as a module using Nushell's *overlays*. Because of Nushell's parse-evaluate model, this
# is actually pretty difficult to do, so we can abuse Nushell hooks to do this.
export def --env "do activate" [] {
    if not ("do.nu" | path exists) {
        error make --unspanned { msg: "No 'do.nu' script found." }
    }

    # The DO_DIR trick is necessary because Nushell doesn't support the special `$env.FILE_PWD` environment
    # variable in modules (see <https://github.com/nushell/nushell/issues/9776>). So, we've invented a convention of
    # using a DO_DIR environment variable to represent the project directory. The 'do.nu' script can use this
    # to fix commands and file references to the right path.
    $env.DO_DIR = (pwd)

    # Here is the tricky part. Register a pre_prompt hook that will load the 'do.nu' script and then the hook will
    # erase itself. I have details about this pattern in my nushell-playground repository: https://github.com/dgroomes/nushell-playground/blob/b505270046fd2c774927749333e67707073ad62d/hooks.nu#L72

    $env.config = ($env.config | upsert hooks.pre_prompt {
        default [] | append $ACTIVATE_DO
    })
}

export alias da = do activate
