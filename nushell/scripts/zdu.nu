# 'zdu' is the 'zero dependency utility' module. All commands in this module have no dependencies.
# They may only use built-in Nushell commands.


# List my Git repositories. By convention, I place them in '~/repos'.
export def repos [] {
    glob --depth 2 ~/repos/*/* | each { |it|

        # The description is the category directory and the repository directory.
        # For example, 'personal/my-software' or 'opensource/nushell'
        let description = $it | path split | last 2 | path join
        { description: $description full_path: $it }
    }
}


# Change to one of my repositories. By convention, my repositories are in categorized subfolders in '~/repos'. For
# example:
#     * ~/repos/opensource/nushell
#     * ~/repos/personal/nushell-playground
#     * ~/repos/personal/my-software
export def --env cd-repo [] {
    let result = repos | fz
    if ($result | is-empty) { return }

    $result | get full_path | cd $in
}


# Copy the last command to the clipboard
export def cp-last-cmd [] {
    history | last 2 | first | get command | pbcopy
}


export def coalesce [...vals] {
    for val in $vals {
        if ($val | is-not-empty) {
            return $val
        }
    }

    # Implicitly returns nothing if we've exhausted the values.
}


# Make a new directory for some "subject". The subject name is optional. If omitted, the created directory's name will
# also include the current time.
#
#     new-subject my-experiment   # Will create the directory '~/subjects/2020-02-09_my-experiment'
#     new-subject                 # Will create the directory '~/subjects/2020-02-09_18-02-05'
#
# Some conventional files are also created: README.md' and 'do.nu'. You are expected to write as much miscellaneous code
# in the 'do.nu' as you need. These files are just a minimal starting point.
export def --env new-subject [subject?] {
    let today = date now | format date "%Y-%m-%d"
    let descriptor = coalesce $subject (date now | format date "%H-%M-%S")
    let dirname = $today + "_" + $descriptor
    let dir = [$nu.home-path subjects $dirname] | path join | path expand
    if ($dir | path exists) {
        error make --unspanned {
          msg: ("The directory already exists: " + $dir)
          help: "Use another subject name."
        }
    }

    mkdir $dir
    print $"Created directory: ($dir). Navigating to it."
    cd $dir

    let title = coalesce $subject "README"

    # Create the conventional files
    $"# ($title)

" | save README.md

    r#'
# Bundle up this subject so that it's ready to be pasted into an AI Chat (LLM).
#
# Specifically, concatenate the README.md, and all the file sets described in each of the '.file-set.json' files.
export def "bundle all" [] {
    let file_sets = glob *.file-set.json | each { bundle file-set $in } | str join ((char newline) + (char newline))

    $"(open --raw README.md)

($file_sets)
" | save --force bundle.txt
}
'# | save do.nu
}


# Like 'which' but it finds more information. This has the effect that you can see if an application is a symlink or
# a normal file which I often need when debugging my PATH.
export def whichx [application: string] {
    let result = which $application

    # When the application is not found.
    if ($result | is-empty) {
        return $result
    }

    # We're only supporting one application in the input, so we know the table will have one row. Let's turn it into a
    # record
    let which_details = $result.0 | into record

    let path_details = (ls -l $which_details.path).0 | into record | select type target
    let merged = $which_details | merge $path_details
    return $merged
}
