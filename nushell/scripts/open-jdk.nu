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
#     Error:   × Error: Expected to find formula 'my-open-jdk@8' but did not.
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
    let keg_dir = [$env.HOMEBREW_PREFIX "opt" $my_open_jdk_at] | path join

    if not ($keg_dir | path exists) {
        err $"Expected to find formula '($my_open_jdk_at)' but did not."
    }

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
export def my-open-jdk-kegs [] {
    let opt_dir = [$env.HOMEBREW_PREFIX "opt"] | path join
    cd $opt_dir

    ls my-open-jdk@* | get name | each {
        let version = $in | split row "@" | get 1 | into int
        assert-my-open-jdk $version
    }
}

def my-open-jdk-keg-versions [] {
    my-open-jdk-kegs | get java_version
}
