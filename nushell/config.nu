# I'm still zeroing in on the ideal sourcing strategy. I would prefer the "sourcing from a directory" approach, but this
 # is not possible. The Nushell docs point this out: https://www.nushell.sh/book/modules.html#dumping-files-into-directory
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

# Switch to the default branch and pull.
#
# I use this workflow frequently to get lined up with the remote before starting some work. I like thinking in terms of
# "default branch" but that's a GitHub term not a Git term. Thankfully, Git basically has the same thing but there isn't
# a word for it. We can think of the HEAD of a remote as the default branch. Use the command "git remote show <remote>"
# to inspect a Git remote using the command "git remote show". For example, "git remote show origin" will
# output something like this:
#
#  $ git remote show origin
#  * remote origin
#    Fetch URL: https://github.com/dgroomes/my-config.git
#    Push  URL: https://github.com/dgroomes/my-config.git
#    HEAD branch: main
#    Remote branches:
#      main                                            tracked
#    Local branches configured for 'git pull':
#      main                        merges with remote main
#    Local ref configured for 'git push':
#      main pushes to main (up to date)
#
# Note that this command actually does a network request. And that's ok because we are going to fire off a network
# request via a "git pull". It's a cheap incremental cost.
export def git-switch-default-pull [] {
    let result = git remote show origin | complete
    if ($result.exit_code != 0) {
        if ($in.stderr | str contains "fatal: not a git repository") {
            error make --unspanned {
              msg: "This is not a Git repository."
            }
            return
        }
        error make --unspanned {
          msg: ("Something unexpected went wrong while inspecting the remote." + (char newline) + $in.stderr)
        }
        return
    }

    let branch = try {
      $result.stdout | lines | find --regex 'HEAD' | get 0 | split words | get 2
    } catch {
        error make {
          msg: "Unexpected problem parsing the default branch from the output of 'git remote show origin'."
        }
    }
    git switch $branch
    git pull
}

export alias clc = cp-last-cmd
export alias ll = ls -l
export alias la = ls -a
export alias gsdp = git-switch-default-pull
