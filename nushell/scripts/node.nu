use zdu.nu err

# Activate a specific version of Node.js that's already installed as a keg. This also deactivates any other Node.js
# versions that are currently active.
#
# This works very similarly to 'open-jdk.nu'. Read that file for more information.
export def --env activate-my-node [version: string@my-node-keg-versions] {
    let node_formula = $"my-node@($version)"
    let keg_dir = [$env.HOMEBREW_PREFIX "opt" $node_formula] | path join

    if not ($keg_dir | path exists) {
        err $"Expected to find formula '($node_formula)' but did not."
    }

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
    let opt_dir = [$env.HOMEBREW_PREFIX "opt"] | path join
    cd $opt_dir

    ls my-node@* | get name | each {
        $in | split row "@" | get 1
    }
}
