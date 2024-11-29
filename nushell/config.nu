# I'm still zeroing in on the ideal sourcing strategy. I would prefer the "sourcing from a directory" approach, but this
# is not possible. The Nushell docs point this out: https://www.nushell.sh/book/modules.html#dumping-files-into-directory
source setup/core.nu
source setup/misc.nu
source setup/nu-scripts-sourcer.nu
source setup/starship.nu
source setup/zoxide.nu
source setup/atuin.nu

use lib/bash-completer.nu *
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

$env.config.completions.external = {
  enable: true
  completer: { |spans| bash-complete $spans }
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
