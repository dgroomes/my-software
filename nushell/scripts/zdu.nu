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
# Some conventional files are also created: 'PROMPT.md' and 'do.nu'. You are expected to write as much miscellaneous code
# in the 'do.nu' as you need. These files are just a minimal starting point geared at bundling up the context for pasting
# into an LLM chat.
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

" | save PROMPT.md

    r#'const DIR = path self | path dirname

# Bundle up the prompt file and all the context described by the "file sets" into a string ready to be pasted into an
# LLM chat app.
export def bundle [] {
    cd $DIR
    let prompt = open --raw PROMPT.md
    let fs_bundles = glob *.file-set.json | each { bundle file-set $in }
    let bun = [$prompt ...$fs_bundles "The original request as a refresher:" $prompt] | str join $"\n\n"

    $bun | save --force bundle.txt
    $bun | pbcopy
    let token_count = $bun | token-count | into int | comma-per-thousand
    print $"Bundle created: ($token_count) tokens and copied to clipboard."
}

export def example-fs [] {
    cd $DIR
    let root = "~/repos/opensource/example"
    let fs_name = "example.file-set.json"

    let fs = do {
        cd $root
        let files = fd --type file | where (is-text-file)
        { root: $root files: $files }
    }

    $fs | save --force $fs_name
    $fs | file-set summarize | table --index false --expand --theme light
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

# I'm not sure why Nushell's error creation is so verbose. I like it in general, but I'm really wanting a shorthand like
# this.
export def err [msg: string] {
    error make --unspanned {
      msg: $msg
    }
}

# We use file names in everyday shell work and I haven't found an ideally compressed way to do this without this custom
# command.
#
# For example, I might want the file name 'package-lock-.json' in my clipboard because I'm going to paste it into a script
# I'm writing or something. The slowest and most error prone way to do this is literally type (and typo) the file name.
#
# One way you might think to do this is type auto-complete 'package-lock.json' directly but that's no good because
# Nushell will try to evaluate it and you'll get 'Command `package-lock.json` not found'.
#
# Another way to do this is type 'ls p' then press tab, which completes both 'package.json' and 'package-lock.json'.
# I click enter to select 'package-lock.json' and now I have to type ' | first | get name | pbcopy'. This is way longer
# than just typing the whole file, although this is actually relatively better for files that are way deep in nested
# directories.
#
# We need a more compressed workflow.
#
# A simple solution is just make a do-nothing command that takes one argument. By default, the file completer is used.
# Return the argument. Easy. That way I can use completions and ultimately express `file-name package-lock.json | pbcopy`
# to get the job done. Often I want the absolute path, so I would do `file-name package-lock.json | path expand` | pbcopy`.
# With aliases, this is pretty compressed.
#
# Addendum: I feel like you could add behavior to a custom completer to just auto-complete file names when you start
# with a double quote. Like `"RE` and then press tab. Right now, it just doesn't complete anything. I might look into
# this.
export def file-name [file] {
    $file
}
