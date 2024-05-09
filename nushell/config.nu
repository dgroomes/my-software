source ([$nu.default-config-dir core.nu] | path join)
source ([$nu.default-config-dir starship.nu] | path join)
source ([$nu.default-config-dir atuin.nu] | path join)
source ([$nu.default-config-dir nu_scripts_sourcer.nu] | path join)


def repos [] {
    glob --depth 2 ~/repos/*/* | each { |it|

        # The description is the category directory and the repository directory.
        # For example, 'personal/my-config' or 'opensource/nushell'
        let description = $it | path split | last 2 | path join
        { description: $description full_path: $it }
    }
}


# Change to one of my repositories. By convention, my repositories are in categorized subfolders in '~/repos'. For
# example:
#     * ~/repos/opensource/nushell
#     * ~/repos/personal/nushell-playground
#     * ~/repos/personal/my-config
export def --env cd-repo [] {
    repos | input list --display description --fuzzy 'Change directory to repository:'
          | if ($in | is-empty) {
              # If the user abandoned the selection, then don't do anything.
              return
            } else { $in }
          | get full_path | cd $in
}


export alias cr = cd-repo


# Copy the last command to the clipboard
export def cp-last-cmd [] {
    history | last | get command | pbcopy
}


export alias clc = cp-last-cmd
export alias ll = ls -l
export alias la = ls -a
