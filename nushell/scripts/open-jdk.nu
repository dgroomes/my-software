use zdu.nu err

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
export def --env activate-my-open-jdk [version: int@my-open-jdk-keg-versions] {
    let jdk_info = assert-my-open-jdk $version

    # Remove any previously active OpenJDKs from the PATH
    $env.PATH = ($env.PATH | where $it !~ "my-open-jdk@")
    # Add the new OpenJDK bin directory to the PATH
    $env.PATH = ($env.PATH | prepend $jdk_info.jdk_bin_dir)

    $env.JAVA_HOME = $jdk_info.jdk_home_dir
}

# Assert that the given version of OpenJDK is installed as a 'my-open-jdk' keg. Also assert that the OpenJDK home and
# bin directories exist at the conventional locations. If the inspection is successful then the basic information about
# the installation is returned.
#
#     $ assert-my-open-jdk 8
#     Error:   × Error: No available formula with the name "my-open-jdk@8".
#
#     $ assert-my-open-jdk 17
#     {
#       formula: "my-open-jdk@17"
#       keg_path: "/opt/homebrew/opt/my-open-jdk@17"
#       java_version: 17
#       jdk_home_dir: "/opt/homebrew/opt/my-open-jdk@17/libexec/Contents/Home"
#       jdk_bin_dir: "/opt/homebrew/opt/my-open-jdk@17/libexec/Contents/Home/bin"
#     }
def assert-my-open-jdk [version: int]: nothing -> record {
    let my_open_jdk_at = $"my-open-jdk@($version)"
    let result = brew --prefix $my_open_jdk_at | complete
    if ($result.exit_code != 0) {
        let err_msg = $result.stderr | str trim
        if ($err_msg =~ "No available formula") {
            err $err_msg
        } else {
            err $"Something unexpected happened while running the 'brew --prefix' command.\n($err_msg)"
        }
    }

    let keg_dir = $result.stdout | str trim
    let jdk_home_dir = [$keg_dir "libexec/Contents/Home"] | path join
    if not ($jdk_home_dir | path exists) {
        err $"Expected to find an OpenJDK home directory at ($jdk_home_dir) but it does not exist."
    }

    let jdk_bin_dir = [$keg_dir "bin"] | path join
    if not ($jdk_bin_dir | path exists) {
        err $"Expected to find a 'bin' directory for the OpenJDK tools at ($jdk_bin_dir) but it does not exist."
    }

    {
        formula: $my_open_jdk_at
        keg_path: $keg_dir
        java_version: $version
        jdk_home_dir: $jdk_home_dir
        jdk_bin_dir: $jdk_bin_dir
    }
}

# List installed OpenJDK kegs.
#
# ╭──────┬──────────────────┬────────────────────────────────────┬────────────────┬──────────────────────────────────────────────────────────┬────────────────────────────────────────╮
# │    # │     formula      │              keg_path              │  java_version  │                       jdk_home_dir                       │              jdk_bin_dir               │
# ├──────┼──────────────────┼────────────────────────────────────┼────────────────┼──────────────────────────────────────────────────────────┼────────────────────────────────────────┤
# │    0 │ my-open-jdk@17   │ /opt/homebrew/opt/my-open-jdk@17   │             17 │ /opt/homebrew/opt/my-open-jdk@17/libexec/Contents/Home   │ /opt/homebrew/opt/my-open-jdk@17/bin   │
# │    1 │ my-open-jdk@21   │ /opt/homebrew/opt/my-open-jdk@21   │             21 │ /opt/homebrew/opt/my-open-jdk@21/libexec/Contents/Home   │ /opt/homebrew/opt/my-open-jdk@21/bin   │
# ╰──────┴──────────────────┴────────────────────────────────────┴────────────────┴──────────────────────────────────────────────────────────┴────────────────────────────────────────╯
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
export def my-open-jdk-kegs [] {
   let result = brew list --formula | complete
   if ($result.exit_code != 0) {
       err $"Something unexpected happened while running the 'brew list' command.\n($result.stderr)"
   }

   $result.stdout | split row (char newline) | where $it =~ "^my-open-jdk@" | each { |formula|
       let version = $formula | split row "@" | get 1 | into int
       assert-my-open-jdk $version
   }
}

def my-open-jdk-keg-versions [] {
    my-open-jdk-kegs | get java_version
}
