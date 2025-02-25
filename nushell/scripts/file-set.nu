# LLM context bundling. This module helps build the 'file set'. The other "bundle" code is haphazardly scattered.

use zdu.nu err
use lib.nu *

def is-nothing [] {
    ($in | describe) == "nothing"
}

# Initialize a new file set from a root directory. For example:
#
#     file-set init /some/project-a
#
# Will create a 'project-a.file-set.json' file in the current directory.
#
export def "file-set init" [ root_dir: string ] {
    if not ($root_dir | path exists) {
        err $"Root directory does not exist: '($root_dir)'"
    }

    let fname = [($root_dir | path basename) ".file-set.json"] | str join
    if ($fname | path exists) {
        err $"File set already exists at '($fname)'"
    }

    { root: $root_dir files: [] } | save $fname

    print $"File set created: '($fname)'"
}

# Validate that a file is a conventional 'file set'. For example:
#
#     file-set validate /some/project-a.file-set.json
#
# Throws an error or returns the object representation of the file set.
#
export def "file-set validate" [file_set]: nothing -> record<root: string, files: list<string>> {
    if not ($file_set | path exists) {
        err $"No file exists at '($file_set)'"
    }

    if not ($file_set | str ends-with ".file-set.json") {
        err $"File '($file_set)' does not have the conventional '.file-set.json' file extension "
    }

    let fso = open $file_set

    let root = $fso | get root?
    if ($root | is-nothing) {
        err $"File set '($file_set)' does not have the 'root' field"
    }

    let files = $fso | get files?
    if ($files | is-nothing) {
        err $"File set '($file_set)' does not have the 'files' field"
    }

    return $fso
}

# Interactively add files and directories to a file set. For example:
#
#     file-set add /some/project-a.file-set.json
#
# Will start a fuzzy-finder with all the files and directories under the root. You can one-by-one select items to add
# to the file set.
#
export def "file-set add" [file_set] {
    let file_set = $file_set | path expand
    cd (file-set validate $file_set).root

    loop {
        mut fso = open $file_set

        # Let's only support files for now.
        let s = fd --type file . | fz
        if ($s | is-nothing) {
            break
        }

        $fso.files = ($fso.files | append $s | sort | uniq)
        $fso | save --force $file_set
    }
}

export def "file-set summarize" [--limit: int = 10] : record<root: string, files: list<string>> -> record {
    let root = $in.root
    let files = $in.files
    cd $root

    # Note: ideally we only use token counting for expressing size, because that's the construct we care about when
    # working with LLMs. But the token counting procedure is very slow to start up because it's in Python. So, we don't
    # token-count every file because there may be a thousand files.
    #
    # So we resort to word-counting to locate the top N largest files. Word count is a useful proxy for token count.
    # Although, there really ought to be faster token counters out there.
    let tokens = $files | each { |it| open --raw $it } | str join $"\n" | token-count | into int | comma-per-thousand
    let largest = $files | par-each { word-counted } | sort-by --reverse words | first $limit | par-each { token-counted } |
        update words { comma-per-thousand } |
        update tokens { comma-per-thousand }

    { root: $root files: ($files | length | comma-per-thousand) tokens: $tokens largest: $largest }
}

def word-counted [] {
    let file = $in
    let wc = open --raw $file | str stats | get words
    { file: $file words: $wc }
}

def token-counted [] {
    let rec = $in
    let tc = open --raw $rec.file | token-count | into int
    $rec | insert tokens $tc
}
