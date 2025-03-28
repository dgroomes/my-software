use zdu.nu err

# Activate a specific version of Node.js that's already installed as a keg. This also deactivates any other Node.js
# versions that are currently active.
#
# This works very similarly to 'open-jdk.nu'. Read that file for more information.
export def --env activate-my-node [version: string@my-node-keg-versions] {
    let node_info = assert-my-node $version

    # Remove any previously active Node.js versions from the PATH
    $env.PATH = ($env.PATH | where $it !~ "my-node@")
    # Add the new Node.js bin directory to the PATH
    $env.PATH = ($env.PATH | prepend $node_info.bin_dir)
}

# Assert that the given version of Node.js is installed as a 'my-node' keg. Also assert that the Node.js bin directory
# exists at the conventional location. If the inspection is successful then the basic information about the installation
# is returned.
#
#     $ assert-my-node "21"
#     Error:   × Error: Expected to find formula 'my-node@21' but did not.
#
#     $ assert-my-node "23"
#     {
#       formula: "my-node@23"
#       keg_path: "/opt/homebrew/opt/my-node@23"
#       node_version: "23"
#       bin_dir: "/opt/homebrew/opt/my-node@23/bin"
#     }
def assert-my-node [version: string]: nothing -> record {
    let my_node_at = $"my-node@($version)"
    let keg_dir = [$env.HOMEBREW_PREFIX "opt" $my_node_at] | path join

    if not ($keg_dir | path exists) {
        err $"Expected to find formula '($my_node_at)' but did not."
    }

    let bin_dir = [$keg_dir "bin"] | path join
    if not ($bin_dir | path exists) {
        err $"Expected to find a 'bin' directory for Node.js at '($bin_dir)' but it does not exist."
    }

    {
        formula: $my_node_at
        keg_path: $keg_dir
        node_version: $version
        bin_dir: $bin_dir
    }
}

# List installed Node.js kegs.
#
# ╭──────┬──────────────────┬────────────────────────────────────┬────────────────┬────────────────────────────────────╮
# │    # │     formula      │              keg_path              │  node_version  │              bin_dir                │
# ├──────┼──────────────────┼────────────────────────────────────┼────────────────┼────────────────────────────────────┤
# │    0 │ my-node@20       │ /opt/homebrew/opt/my-node@20       │             20 │ /opt/homebrew/opt/my-node@20/bin   │
# │    1 │ my-node@23       │ /opt/homebrew/opt/my-node@23       │             23 │ /opt/homebrew/opt/my-node@23/bin   │
# ╰──────┴──────────────────┴────────────────────────────────────┴────────────────┴────────────────────────────────────╯
#
export def my-node-kegs [] {
    let opt_dir = [$env.HOMEBREW_PREFIX "opt"] | path join
    cd $opt_dir

    ls my-node@* | get name | each {
        let version = $in | split row "@" | get 1
        assert-my-node $version
    }
}

def my-node-keg-versions []: nothing -> list<string> {
    my-node-kegs | get node_version
}

# Discover keg installations of Node.js and make them available (i.e. "advertise") as version-specific "NODEJS_HOME"
# environment variables.
#
# For example, for a Node.js 23 keg installed at "/opt/homebrew/opt/my-node@23" then set the environment
# variable "NODEJS_HOME_23" to that path.
export def --env advertise-installed-nodes [] {
    for keg in (my-node-kegs) {
        let nodejs_x_home = $"NODEJS_($keg.node_version)_HOME"
        load-env { $nodejs_x_home: $keg.keg_path }
    }
}
