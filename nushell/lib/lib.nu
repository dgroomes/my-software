# My own library of commands.

use node.nu *
use open-jdk.nu *
use postgres.nu *
use zdu.nu *

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
#    Fetch URL: https://github.com/dgroomes/my-software.git
#    Push  URL: https://github.com/dgroomes/my-software.git
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
        if ($result.stderr | str contains "fatal: not a git repository") {
            error make --unspanned {
              msg: "This is not a Git repository."
            }
            return
        }
        error make --unspanned {
          msg: ("Something unexpected went wrong while inspecting the remote." + (char newline) + $result.stderr)
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



# Activate a default OpenJDK, Node.js, etc.
#
# Oddly, at this point, $env.PATH is the typical colon-delimited value that we are familiar with in most environments.
# In Nushell, $env.PATH is supposed to be a list but I guess we are too early in the bootstrapping process? Anyway, we
# have to parse it into a list. Let' take the naive approach (after some quick searching I didn't find a better way)
# and split on ":" (or are colons not allowed anywhere in paths and files across all systems?).
export def --env activate-defaults [] {
    let default_java = 21
    let default_node = "20"
    let default_postgres = "17"

    let split_path = $env.PATH | split row ":"
    $env.PATH = $split_path
    try { activate-my-open-jdk $default_java } catch { print "(warn) A default OpenJDK was not activated." }
    try { activate-my-node $default_node } catch { print "(warn) A default Node.js was not activated." }
    try { activate-postgres $default_postgres } catch { print "(warn) A default Postgres was not activated." }
}


# Find all "dirty" (changes haven't been committed) Git projects recursively underneath some directory.
#
# This function is useful to run from time to time because of the "I don't want to lose my precious code" scenario. Days
# and weeks ago you probably wrote some interesting code or notes but you never committed them because you got
# side-tracked, you got stuck, or you ran out of time. You want a chance to revisit these changes and either officially
# discard them or decide that they're useful and follow up on them. I especially feel this need when I'm about to
# switch to a new computer.
#
# For example:
#
#   $ dirty-git-projects ~/repos/personal
#   Searching for Git projects in '/Users/dave/repos/personal' at a depth of 1 ...
#   Found 75 Git projects.
#   Found 3 dirty Git projects:
#   ╭───┬──────────────────────────────────────────────╮
#   │ 0 │ /Users/dave/repos/personal/my-software         │
#   │ 1 │ /Users/dave/repos/personal/react-playground  │
#   │ 2 │ /Users/dave/repos/personal/ruby-playground   │
#   ╰───┴──────────────────────────────────────────────╯
#
export def dirty-git-projects [search_directory = "." --depth: int = 1] {
    # Consider this command:
    #
    #    dirty-git-projects ~/repos --depth 2
    #
    # Our objective is to find Git projects like:
    #
    #    ~/repos/personal/react-playground
    #    ~/repos/opensource/react
    #
    # A convenient way to find Git projects is to look for '.git' directories. A '.git' directory is one level deeper
    # than the depth of the Git projects themselves. So in this case, we need to glob search at 3 (2 + 1) levels deep.
    # We need this command.
    #
    #     glob ~/repos/**/.git --depth 3
    #
    # Note: 'glob' is doing a lot of heavy lifting here. It's expanding the tilde ('~') character and it's
    # interpreting the '**' wildcard to mean "search recursively". Very neat.
    #
    # Note: 'par-each' is a parallel version of 'each'. See https://www.nushell.sh/book/parallelism.html#par-each . This
    # gives us a legit speed boost. I would prefer to use a parallel version of 'where' but there isn't one.
    let search_glob_string = [$search_directory "**/.git"] | path join
    glob $search_glob_string --depth ($depth + 1)
        | each { || path dirname } # Get the parent directory of the '.git' directory
        | sort
        | par-each { |it| if (is-git-project-dirty $it) { $it } }
}


# Is the given Git project's working tree dirty?
#
# For example:
#
#    is-git-project-dirty ~/repos/personal/my-software        # true (a.k.a. "dirty". There are uncommitted changes.)
#    is-git-project-dirty ~/repos/personal/react-playground # false (a.k.a "clean". There are no uncommitted changes.)
#
def is-git-project-dirty [project_path] {
    # The 'git status --porcelain' command is a machine-readable version of 'git status'. That's exactly what we
    # need. Each line represents a changed file. If the output is empty, then the working tree is clean.
    #
    # For example:
    #
    #    $ git status --porcelain
    #    A  go/go.mod
    #    A  go/go.sum
    #    AD go/main.go
    #    AM nushell/git-summarize.nu
    #
    let result = git -C $project_path status --porcelain | complete
    if ($result.exit_code != 0) {
        let error_msg = $"Something unexpected happened while running the 'git' command at '($project_path)' (char newline) ($result.stderr)"
        error make --unspanned { msg: $error_msg }
    }
    $result.stdout | is-not-empty
}


# Run a shell command expressed in the README (Markdown) file in the current directory.
#
# I often write specific "how to build and run this project" instructions in the README.md files in my projects. The
# instructions include shell commands authored inside "code fences" (triple back-ticks). I usually execute these
# snippets by clicking the green play button that appears to the left of the instructions. This button is in the
# "gutter" part of the editor window in Intellij. This is super convenient. Later, I might re-execute the commands by
# using shell history (Ctrl-R) on the commandline. This is all perfectly fine, but I'd prefer to compress this workflow
# even further.
#
# This command implements a compressed workflow. It parses shell snippets from the README.md file using the
# 'markdown-code-fence-reader' program (source code is also in this repository), presents the snippets in a selectable
# list and then rewrites the commandline with the selected snippet. It does NOT execute the command. You still need to
# press the enter key, and better yet, you should also review the command before executing it.
export def run-from-readme [] {
    let readme_path = "README.md" | path expand
    if not ($readme_path | path exists) {
        print "No README.md file"
        return
    }

    which markdown-code-fence-reader | if ($in | is-empty) {
        error make --unspanned { msg: "The 'markdown-code-fence-reader' program is not installed." }
    }

    let result = markdown-code-fence-reader $readme_path | complete

    if ($result.exit_code != 0) {
        let msg = "Something unexpected happened while running the 'markdown-code-fence-reader' command." + (char newline) + $result.stderr
        error make --unspanned { msg: $msg }
    }

    let shell_snippets = $result.stdout | from json | where { |snippet|
        [shell nushell bash] | any { |lang| $snippet.language == $lang }
    }

    if ($shell_snippets | is-empty) {
        print "No shell snippets found."
        return
    }

    let snippet = $shell_snippets | fz --filter-column content
    if ($snippet | is-empty) {
        # If the user abandoned the selection, then don't do anything.
        return
    }

    # For 'nushell' command snippets, we write it directly to the commandline. If the user wants to execute the command,
    # they press enter, and if they want to edit it then they edit it. I personally really like this workflow.
    if $snippet.language == "nushell" {
        $snippet.content | commandline edit $in
        return
    }

    if $snippet.language != "shell" and $snippet.language != "bash" {
        error make --unspanned { msg: $"Unexpected snippet language found. ($snippet.language)" }
    }

    # NOTE: This is commented out, because sadly, the "new" Nushell parser is missing a critical mass of features so I can't do this check
    #
    # For shell/bash commands, check if they are simple enough to use directly in Nushell
    # without escaping into bash -c
    # let compatibility_result = $snippet.content | posix-nushell-compatibility-checker | complete
#
    # if $compatibility_result.exit_code == 0 {
    #     # Command is compatible with Nushell, use it directly
    #     $snippet.content | commandline edit $in
    #     return
    # }

    # If the snippet is a Bash command or otherwise a generic shell (likely POSIX) command, then we have some more work
    # to do. We can't write the command as-is because it will usually not be legal Nu syntax. We can splice it into the
    # commandline in the "-c" option of the "bash" command. For example, if the command is:
    #
    #     wc -l > line-counts.txt
    #
    # then, we could write:
    #
    #     bash -c 'wc -l > line-counts.txt'
    #
    # But the Bash snippet really needs proper treatment to avoid string/escape problems. I think Nushell's "raw strings"
    # feature will work great here (https://www.nushell.sh/book/working_with_strings.html#raw-strings).
    # To do it right, we need to find the occurrence of the raw string ending sequence ('#') with the most consecutive
    # hashtag symbols. Of course it's unlikely that a Bash/shell snippet would ever contain that sequence, we can easily
    # cover this case. For example, consider this Bash/shell snippet:
    #
    #     cat << 'EOF' > README.md
    #     # "Parser Thinking": What are the grammar rules?
    #
    #     Here is some Nushell code:
    #
    #     ```nushell
    #     r###'r##'This is an example of a raw string.'##'###
    #     ```
    #     EOF
    #
    # First of all, there are lots of different Bash parsing/grammar things happening here. But it's the hash symbols plus
    # apostrophe that are a real threat. To express this snippet on the Nushell commandline, we need to start a raw string
    # with a four-length r/hashtag sequence. It would look like this
    #
    #     r####'cat << 'EOF' > README.md
    #     # "Parser Thinking": What are the grammar rules?
    #
    #     Here is some Nushell code:
    #
    #     ```nushell
    #     r###'r##'This is an example of a raw string.'##'###
    #     ```
    #     EOF'####
    #
    # Alternatively, I could just save the snippet to a constant variable and then populate the commandline with something
    # like:
    #
    #    bash -c $RUN_FROM_README_SNIPPET
    #
    # And that might be a more sane approach. But it doesn't let you edit the command before executing it, and that
    # command is not useful in history, and we're left with a constant variable in scope.
    #
    # There's another edge case we have to handle (always be wary of string concatenation/injection). A Bash/shell snippet
    # can start with a '#' character, because that's the comment syntax (and other cases?). What if we just add a newline
    # to the top and bottom of the snippet, and then trim it before passing it to the 'bash' command? That will make the
    # snippet more isolated and readable even in the normal case. For example, for the Bash snippet:
    #
    #     # This is a comment
    #
    # We want to write the commandline as:
    #
    #     bash -c (r#'
    #     # This is a comment
    #     '# | str substring 1..-2)
    #
    # Wow, that's dense! And it's even denser to construct that string from within Nushell code... This might not be
    # worth doing, but I still like the end result. I would like access to a proper Nu language string escaping function.
    #
    let sequences = $snippet.content | parse --regex "'+(#+)"
    let max_length = if ($sequences | is-empty) {
        0
    } else {
        $sequences | get capture0 | each { $in | str length } | sort | last
    }

    let repetitive_hashtags = '' | fill --character '#' --width ($max_length + 1)

    let template = r#'bash -c (r%REPETITIVE_HASHTAGS%'
%SNIPPET_CONTENT%
'%REPETITIVE_HASHTAGS% | str substring 1..-2)'#

    let command_line = $template | str replace --all "%REPETITIVE_HASHTAGS%" $repetitive_hashtags | str replace "%SNIPPET_CONTENT%" $snippet.content
    $command_line | commandline edit $in
}


# Execute the Gradle wrapper ('gradlew') with the given arguments.
#
# 'gw' is short for "Gradle wrapper". This command looks for the 'gradlew' file in the current directories and containing
# directories until it finds it.
#
# For example:
#
#    gw build
#    gw --verbose my-project:installDist
#
# One downside of this is that shell completion won't work for the 'gradle' command. Although I rarely ever used that
# because it's very slow and there are tons of commands. But it's still a downside.
export def --wrapped gw [...args] : nothing {
    mut dir = (pwd)
    loop {
        let gradlew = $dir | path join "gradlew"
        if ($gradlew | path exists) {
            run-external $gradlew ...$args
            return
        }

        let parent = $dir | path dirname
        if ($parent == $dir) { # We've bottomed out at the root directory
            error make --unspanned { msg: "No 'gradlew' script found." }
        }
        $dir = $parent
    }
}

# 'fz' is a Nushell command and wrapper over the 'my-fuzzy-finder' program. I called it 'fz' because it's in the spirit
# of 'fzf' but is distinct from it, and I like how short the 'fz' name is.
#
# 'fz' adds the Nushell experience to 'my-fuzzy-finder' by supporting structured input and output and commandline
# completions.
#
# For input tables, 'fz' will extract a "filter column" from the input table and pass the values as lines into
# 'my-fuzzy-finder'. 'fz' will use the first table column as the filter column, or it will use the one specified by
# the optional "--filter-column" flag. After you've selected a row, 'fz' will then convert the JSON object returned by
# 'my-fuzzy-finder' into a record and return that.
#
# For example, fuzzy find files in the current directory:
#
#   $ ls | fz
#
#    ... You are in the TUI now. The 'name' column is used as the filter column because it is the first column in the
#        table output by 'ls'. You interactively narrow down the list by typing 'mod'. You press enter.
#
#   ╭──────────┬────────────╮
#   │ name     │ go.mod     │
#   │ type     │ file       │
#   │ size     │ 1.2 KiB    │
#   │ modified │ 2 days ago │
#   ╰──────────┴────────────╯
#
# Or you can fuzzy find on other columns using commands like:
#
#   $ ls | fz --filter-column type
#   $ ls | fz -f size
#   $ ls | fz -f modified
#
# 'fz' also supports lists as input. So, for example, you can do:
#
#   $ glob */** | fz
#
export def fz [--filter-column (-f): string] [list<string> -> string, table -> record] {
    which my-fuzzy-finder | if ($in | is-empty) {
        error make --unspanned { msg: "The 'my-fuzzy-finder' program is not installed." }
    }

    let _in = $in
    if ($_in | is-empty) {
        print "(fz) No input"
        return
    }

    let in_type = if ($_in | describe | str starts-with table) {
        "table"
    } else if ($_in | describe | str starts-with list) {
        "list"
    } else {
        error make --unspanned { msg: "Unsupported input type." }
    }

    let item_strings = match $in_type {
        "table" => {
            let _filter_column = if ($filter_column | is-not-empty) { $filter_column } else { $_in | columns | first }
            $_in | get $_filter_column
        }
        "list" => {
            $_in
        }
    }

    let result = $item_strings | to json | my-fuzzy-finder --json-in --json-out | complete

    match $result.exit_code {
        0 => {
            # Success
        }
        1 => {
            # This is a normal case. When there are no matches, 'my-fuzzy-finder' exits with a 1 status code. This is
            # the same behavior as 'fzf'.
            print "(fz) No match"
            return
        }
        130 => {
            # This is a normal case. When the user abandons the selection, 'my-fuzzy-finder' exits with a 130 status
            # code. This is the same behavior as 'fzf'.
            return
        }
        _ => {
            error make --unspanned { msg: "Something went wrong. Received an unexpected status code from 'my-fuzzy-finder'." }
        }
    }

    let output_record = ($result.stdout | from json)
    return ($_in | get $output_record.index)
}


# Let's wrap 'fd' to give it the Nushell treatment. Instead of outputting new-line delimited text, the wrapped 'fd'
# command will output a proper Nushell list.
#
# Warning: In general, shadowing or overwriting well-known and highly-depended
# upon APIs is a severe mistake. In your own shell, I can be convinced that it's ok. I'm still not really sure. But I'm
# going to try it out.
export def --wrapped fd [...args] {
    ^fd ...$args | split row (char newline)
}


# Similar to 'cat' but bookends the file content with frontmatter and a footer. For example:
#
# --- FILE ---
# File: src/README.md
# Line count: 3
# --- START OF FILE ---
# # my-project
#
# Hello world!
# --- END OF FILE 'src/README.md' ---
#
#
# The advantage of restating the file name in the footer is that it helps to reground the reader (i.e you ar an LLM) to
# remember what file it's been looking at. This is especially useful for huge files.
#
# The 'in' parameter is either a file name or a list of file names.
export def cat-with-frontmatter [] : [string -> string, list<string> -> string] {
    let in_type = ($in | describe)
    let x = match $in_type  {
        "list<string>" => $in
        "string" => [$in]
        _ => {
            error make --unspanned { msg:  $"'cat-with-filename' expects a list of file names (list<string>) or a single file name (string) but found ()." }
        }
    }

    $x | enumerate | each { |it|
        let index = $it.index + 1
        let path = $it.item
        let content = (open --raw $path)
        let line_count = ($content | lines | length)
        $"--- FILE ($index) ---
File: ($path)
Line count: ($line_count)
--- START OF FILE ---
($content)
--- END OF FILE '($path)' ---"
    } | str join ((char newline) + (char newline))
}

export def "bundle file-set" [file_set: string --save] -> string {
    let name = $file_set | path basename | str replace --regex '\.file-set\.json$' ''
    let fs_obj = (open --raw $file_set | from json)

    cd $fs_obj.root
    let files_content = $fs_obj.files | cat-with-frontmatter
    cd -

    # Note: we are restating the file set name at the end of the content to help the reground reader (i.e. you or an LLM)
    # on which logical file set they were just reading. This especially useful for large files sets and/or file sets
    # with huge files.
    let full_content = $"--- FILE SET ---
File set: ($name)
Files: ($fs_obj.files | length)
---

($files_content)
--- END OF FILE SET '($name)' ---
"

    if $save {
        $full_content | save --force ($name + '.file-set-bundle.txt')
    }

    $full_content
}


# Turn a JetBrains "project details" JSON document (defined by 'my-intellij-plugin') into a 'file set' JSON document
# which is designed to be used in bundling.
export def project-details-to-file-set []: [record -> record] {
    let root = $in.project_base_path
    let files = ($in.open_files | get path | path relative-to $root)

    { root: $root, files: $files }
}

export def is-text-file [file_name?: string --print] [string -> bool, nothing -> bool] {
    let _file_name = coalesce $file_name $in

    # I don't know a super idiomatic way to do this. But using the 'str stats' command is a neat trick to try to figure
    # out if a file is text or not (some binary). I looked into mime types but that's not really the right fit because
    # that's an always growing list of stuff.

    try {
        # Around the time I upgraded to Nushell 0.98.0, the 'str stats' result started printing in the shell. This is odd
        # because the overall 'is-text-file' command returns either false or true. A command should only cause something
        # to render in the shell if its printed or its the return/output of the command, right? So I'm using 'ignore' now.
        open --raw $_file_name | str stats | ignore
    } catch {
        if $print {
            print $"'($_file_name)' is not a text file."
        }
        return false
    }

    return true
}


# Upgrade the Gradle wrapper in the current directory and subdirectories.
#
# This function searches for Gradle projects in the current directory and subdirectories. It upgrades the Gradle wrapper
# in each project to the specified version.
export def upgrade-gradle-wrapper [gradle_version: string = "8.10"  --depth: int = 1] {
    let gradle_wrapper_files = glob --depth $depth **/gradlew

    if ($gradle_wrapper_files | is-empty) {
        print $"No Gradle projects found here or in subdirectories at a depth of ($depth)."
        return
    }

    for wrapper_file in $gradle_wrapper_files {
        let project = $wrapper_file | path dirname
        print $"Upgrading Gradle wrapper to version ($gradle_version) for project: ($project)"

        cd $project
        # I don't totally understand why I need the fully qualified path. I haven't grokked knowing when 'run-external'
        # is needed.
        let wrapper_file_fully_qualified = $wrapper_file | path expand
        run-external $wrapper_file_fully_qualified "wrapper" "--gradle-version" $gradle_version
        cd -
    }
}

# Open a directory or file in Visual Studio Code
export def code [file_or_dir: string] {
    let path = $file_or_dir | path expand
    ^open -a `/Applications/Visual Studio Code.app` $path
}

# Open a directory or file in XCode
export def xcode [file_or_dir: string] {
    let path = $file_or_dir | path expand
    ^open -a /Applications/Xcode.app $path
}
