
def fake_rm [file] {
    print $"Fake removing ($file)..."
}

# unused but I thought I needed it. Learned that you need a loop to do an early return.
def coalesce [...vals] {
    for val in $vals {
        if ($val | is-not-empty) {
            return $val
        }
    }

    return null
}

# Does the record contain a particular key?
#
# For example:
#
#     { a: 1 } | has a     # true
#     { a: 1 } | has b     # false
#     { a: null } | has a  # true
#
def has [element] {
    let record = $in
    try {
        $record | get $element; true
    } catch { false }
}

# DOES NOT WORK
# Nushell doesn't have a set data type so I'm using a record (dictionary) in its place. Given a list of
# strings, I need a record so that I can have the traditional "Does set A have element B" function.
def strings_into_record [] : [list<string> > record<string, nothing>] {
    let record = {}
    let strings = $in
    print $"in: ($in)"

    for string in $strings {
        record = $record | upsert $string null
    }

    return $record
}

# I don't know how to declare "use file completion" (like I want to use in the 'trash' command) so I'm implementing a
# poor version of it here.
def files [] {
    ls | get name
}


# An 'rm' alternative that is both interactive and moves files to the trash (macOS) instead of deleting them permanently.
#
# I'm starting simple. But I'd like to support more features like a variable number of arguments.
#
# For example:
#     irm README.md
#     irm my-project
export def irm [file: string@files] {
    let choice = input []
    fake_rm $file
}

# WORK IN PROGRESS
#
# I want a safer 'rm' workflow. Ideally it can be faster too. Nushell's version of 'rm' is pretty neat because it has
# both a '--trash' option and an '--interactive' option. This should get me pretty far as-is. I especially like the
# idea of an "only trash, never straight delete" workflow so I imagine a command like 'trash' (which is mostly 'rm --trash'
# under-the-hood) would be a good fit. But I'm also tempted to compress the need to specify '--recursive' too. What if
# I had a "safe remove"-style of command (named "trash", "safe-rm", "rm-safe", "smart-rm", "sweep", or something...) that trashed anything given
# to it, but then had some safeguards like 'never accidentally attempt to trash a super directory like "/", "~", "~/repos",
# or even a directory that meets a size threshold, or a directory with uncommitted changes... The command is built for
# me for interactive use. No need to cater to anyone else.
#
def itrash [] {
  let user_input = input --numchar 1 --suppress-output "Confirm deletion of file 'xyz'? Press 'y' to delete. Press 'n' to cancel (press enter to cancel)"
  print $"Received: ($user_input)"
}
