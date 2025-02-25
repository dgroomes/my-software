use zdu.nu err

# Activate a specific version of Node.js that's already installed as a keg. This also deactivates any other Node.js
# versions that are currently active.
#
# This works very similarly to 'open-jdk.nu'. Read that file for more information.
export def --env activate-my-node [version: string@my-node-keg-versions] {
    let result = brew --prefix $"my-node@($version)" | complete
    if ($result.exit_code != 0) {
        err $"Something unexpected happened while running the 'brew --prefix' command.\n($result.stderr)"
    }

    let keg_dir = $result.stdout | str trim
    let bin_dir = [$keg_dir "bin"] | path join
    if not ($bin_dir | path exists) {
        err $"Expected to find a 'bin' directory for Node.js at '($bin_dir)' but it does not exist."
    }

    # Remove any previously active Node.js versions from the PATH
    $env.PATH = ($env.PATH | where $it !~ "my-node@")
    # Add the new Node.js bin directory to the PATH
    $env.PATH = ($env.PATH | prepend $bin_dir)
}

def my-node-keg-versions []: nothing -> list<string> {
    let result = brew list --formula | complete
    if ($result.exit_code != 0) {
        err $"Something unexpected happened while running the 'brew list' command.\n$result.stderr"
    }

    $result.stdout | split row (char newline) | where $it =~ "^my-node@" | each { |it| $it | split row "@" | get 1 }
}
