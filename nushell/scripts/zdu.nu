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

# Often we will expand a tilde-containing path string. For example:
#
#     Original:    ~/my-project
#     Expanded:    /Users/me/my-project
#
# This command does the reverse.
#
export def compress-home [] {
    let p = $in
    if ($p | str starts-with $env.HOME) {
        $p | str replace $env.HOME "~"
    } else {
        $p
    }
}

# Convert a Unix epoch timestamp to a `datetime`
#
# This command is all about practical convenience. I often encounter Unix epoch timestamps. But they are all over the
# place in terms of input shapes: seconds, milliseconds, strings and integers. This command handles them all. In a more
# formal program, we would prefer to be stricter about the inputs.
#
# This command is named "epoch-into-datetime" to match the existing "into {type}" family of builtin Nushell commands.
#
@example "epoch as integer seconds" { 1751545681 | epoch-into-datetime } --result 2025-07-03T07:28:01-05:00
@example "epoch as string seconds" { "1751545681" | epoch-into-datetime } --result 2025-07-03T07:28:01-05:00
@example "epoch as milliseconds" { 1751545681999 | epoch-into-datetime } --result 2025-07-03T07:28:01-05:00
export def epoch-into-datetime []: [string -> datetime, int -> datetime, float -> datetime] {
    let raw = $in

    # Normalise to integer
    let ts_int = match ($raw | describe) {
        "int"    => $raw
        "float"  => ($raw | into int)
        "string" => (try { $raw | str trim | into int } catch {
            error make --unspanned { msg: $"Input string ($raw) is not a valid integer epoch timestamp." }
        })
        _ => (error make --unspanned { msg: $"Unsupported input type: ($raw | describe)" })
    }

    # Truncate to seconds
    let ts_secs = if ($ts_int >= 1_000_000_000_000) or ($ts_int <= -1_000_000_000_000) {
        $ts_int / 1000 | into int
    } else {
        $ts_int
    }

    # For convenience, let's attach the local timezone into the datetime record. I can make better sense of a locally
    # formatted date/time string than one in UTC.
    $ts_secs | into datetime -f '%s' | date to-timezone LOCAL
}
