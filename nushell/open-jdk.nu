# Activate a specific version of OpenJDK that's already installed as a keg. This also deactivates any other OpenJDKs
# that are currently active.
#
# By "activate", we need to adapt the PATH to include the directory containing all the OpenJDK executables like "javac",
# "jshell", "java" etc. And, we need to set the environment variable "JAVA_HOME" to the OpenJDK installation directory.
# Many tools, like Gradle, rely on the "JAVA_HOME" environment variable.
#
# The mechanism of "activating a Homebrew keg" is happily generic. So-called "keg-only" formulas are not symlinked into
# a conventional directory like "opt/homebrew/bin" and thus the installed software does not appear on your PATH. I think
# it's pretty easy to just dynamically modify the PATH to include the "bin" directory of the keg. In Nushell, this
# is especially painless because the PATH environment variable is a list (structured data) instead of a colon-delimited
# string like it is in most shells.
export def --env activate-my-open-jdk [version: string@my-open-jdk-keg-versions] {
    let result = brew --prefix $"my-open-jdk@($version)" | complete
    if ($result.exit_code != 0) {
        error make --unspanned {
            msg: ("Something unexpected happened while running the 'brew --prefix' command." + (char newline) + $result.stderr)
        }
    }

    let keg_dir = $result.stdout | str trim
    let jdk_home_dir = [$keg_dir "libexec/openjdk/Contents/Home"] | path join
    if not ($jdk_home_dir | path exists) {
        error make --unspanned {
            msg: ($"Expected to find an OpenJDK home directory at ($jdk_home_dir) but it does not exist.")
        }
    }

    let bin_dir = [$keg_dir "bin"] | path join
    if not ($bin_dir | path exists) {
        error make --unspanned {
            msg: ($"Expected to find a 'bin' directory for the OpenJDK tools at ($bin_dir) but it does not exist.")
        }
    }

    # Remove any previously active OpenJDKs from the PATH
    $env.PATH = ($env.PATH | where $it !~ "my-open-jdk@")
    # Add the new OpenJDK bin directory to the PATH
    $env.PATH = ($env.PATH | prepend $bin_dir)

    $env.JAVA_HOME = $jdk_home_dir
}

# List the OpenJDK versions of my OpenJDK kegs.
#
# For example, this returns a list of strings like ["17", "21", "23"].
#
# By convention, my OpenJDK formulas are named like "my-open-jdk@17", "my-open-jdk@21", etc.
#
# Unfortunately, this is very slow because "brew list --formula" is slow. It's like 2 seconds, and the command is
# seemingly re-executed for every character that you type. Here's an example:
#   1. I type "activate-my-open-jdk " then tab. 2 second pause.
#   2. I type "17" but nothing is rendered. There is a 2 second pause.
#   3. The "1" shows up. There is a 2 second pause.
#   4. The "7" shows up. There is a 2 second pause (during this time, pressing enter has no effect).
#   5. I press "enter". Finally, the command is executed.
#
# Should we just read the keg directories? It's either that, or cache it (which creates its own problems), or just
# hand-type "activate-my-open-jdk 21". I think the last option is the best. The command will be in my history at all
# times so it's really not a problem. It's not like I'm frequently shopping between many installed versions of OpenJDK.
def my-open-jdk-keg-versions [] -> list<string> {
    let result = brew list --formula | complete
    if ($result.exit_code != 0) {
        error make --unspanned {
            msg: ("Something unexpected happened while running the 'brew list' command." + (char newline) + $result.stderr)
        }
    }

    $result.stdout | split row (char newline) | where $it =~ "^my-open-jdk@" | each { |it| $it | split row "@" | get 1 }
}
