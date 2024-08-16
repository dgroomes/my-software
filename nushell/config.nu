# I'm still zeroing in on the ideal sourcing strategy. I would prefer the "sourcing from a directory" approach, but this
# is not possible. The Nushell docs point this out: https://www.nushell.sh/book/modules.html#dumping-files-into-directory
# Let's let 'core.nu' go first. The rest let's organize alphabetically.
source ([$nu.default-config-dir core.nu] | path join)

source ([$nu.default-config-dir atuin.nu] | path join)
source ([$nu.default-config-dir node.nu] | path join)
source ([$nu.default-config-dir nu-scripts-sourcer.nu] | path join)
source ([$nu.default-config-dir open-jdk.nu] | path join)
source ([$nu.default-config-dir postgres.nu] | path join)
source ([$nu.default-config-dir starship.nu] | path join)

# I don't really understand the essential coverage, or purpose, of the directories added to the PATH by the macOS
# "/usr/libexec/path_helper" tool. But, at the least, I know it adds "/usr/local/bin" to the PATH and I need that.
# I'm not going to dig into this further. I just vaguely know about /etc/paths and /etc/paths.d and today I learned
# or maybe re-learned about /etc/profile and /etc/bashrc.
$env.PATH = ($env.PATH | append "/usr/local/bin")

$env.config.buffer_editor = "subl"

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

export alias cdr = cd-repo

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

# Make a new directory for some "subject". The subject name is optional. If omitted, the created directory's name will
# also include the current time.
#
#     mkdir-subject my-experiment   # Will create the directory '~/subjects/2020-02-09_my-experiment'
#     mkdir-subject                 # Will create the directory '~/subjects/2020-02-09_18-02-05'
def --env mkdir-subject [subject?] {
    let today = date now | format date "%Y-%m-%d"
    let descriptor = if ($subject != null) { $subject } else { date now | format date "%H-%M-%S" }
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
}

export alias clc = cp-last-cmd
export alias ll = ls -l
export alias la = ls -a

# Git aliases
export alias gsdp = git-switch-default-pull
export alias gs = git status

# Docker aliases
export alias dcl = docker container ls
## This is what I'll call a "hard restart" version of the "up" command. It forces the containers to be created fresh
## instead of being reused and it does the same for anonymous volumes. This is very convenient for the development process
## where you frequently want to throw everything away and start with a clean slate. I use this for stateful workloads like
## Postgres and Kafka.
export alias dcuf = docker-compose up --detach --force-recreate --renew-anon-volumes
export alias dcd = docker-compose down --remove-orphans

# Miscellaneous aliases
export alias psql_local = psql --username postgres --host localhost

let bash_completer =  { |spans|
    which bash | if ($in | is-empty) {
        # Note: you won't see this message when the closure is invoked by Nushell's external completers machinery.
        # Silencing (or "swallowing") the output of a rogue completer is designed as a feature. Totally fair, but that
        # makes debugging external completer closures difficult. See the 'bash-complete' function which is designed to
        # wrap this closure, which let's you see output like this normally. I didn't have any luck with the standard
        # library logger or the internal logs (e.g. `nu --log-level debug`) either.
        print "Bash is not installed. The Bash completer will not be registered."
        return
    }

    let one_shot_bash_completion_script = [$nu.default-config-dir one-shot-bash-completion.bash] | path join | if ($in | path exists)  {
        $in | path expand
    } else {
        print "The one-shot Bash completion script does not exist. No completions will be available."
        return
    }

    let line = $spans | str join " "

    let result = with-env {
        BASH_COMPLETION_INSTALLATION_DIR: /opt/homebrew/opt/bash-completion@2
        BASH_COMPLETION_USER_DIR: ([$env.HOME .local/share/bash-completion] | path join)
        BASH_COMPLETION_COMPAT_DIR: /disable-legacy-bash-completions-by-pointing-to-a-dir-that-does-not-exist
    } {
        run-external $one_shot_bash_completion_script $line | complete
    }

    # The one-shot Bash completion script will exit with a 127 exit code if it found no completion definition for the
    # command. This is a normal case, because of course many commands don't have or need completion definitions. At
    # this point, we can't just return an empty list because that would be interpreted by Nushell as "completion options
    # were found to be empty", and the Nushell command line would show "NO RECORDS FOUND". We don't want that. We want
    # Nushell to fallback to file completion. For example, we want "cat " to show the files and directories in the
    # current directory.
    #
    # Right now (2024-06-21) there is not a way to tell Nushell that no completion definitions were found (see https://github.com/nushell/nushell/issues/6407#issuecomment-1227250012)
    # but we can return unparseable JSON (see the note in https://www.nushell.sh/book/custom_completions.html#custom-descriptions)
    # or we can throw an error. In either case, Nushell's completion machinery will actually catch the error and show
    # the error message in a very fast flash of text on the command line. For example, https://github.com/nushell/nushell/blob/10e84038afe55ba63c9b3187e6d3a1749fa2cc65/crates/nu-cli/src/completions/completer.rs#L115
    # While that's a little awkward, I'm perfectly happy with that. It's so fast you can't even read it (although you'll
    # notice the flash). To limit the size of the flashing text, I'll actually use a short error message.
    if ($result.exit_code == 127) {
        error make --unspanned {
            msg: ("No defs.")
        }
    }

    if ($result.exit_code != 0) {
        error make --unspanned {
            msg: ("Something unexpected happened while running the one-shot Bash completion." + (char newline) + $result.stderr)
        }
    }

    # There are a few data quality problems with the completions produced by the Bash script. It's important to note
    # that the Bash completion functions are able to produce anything they want. I've found that the completions for
    # 'git' return duplicates when I do "git switch ". For example, for a repository that only has one branch ("main"),
    # the completion scripts produce "main" twice. I only see that in my non-interactive flow, and I'm taking a wild
    # guess that Bash has some presentation logic that actually de-duplicates (and sorts?) completions before presenting
    # them to the user. Nushell does not do de-duplication of completions (totally fair).
    #
    # Another problem is the trailing newline produced by the Bash script. In general, you just need to be careful with
    # the characters present in completion suggestions because Nushell seems to just let it fly. So a newline really
    # messes things up.
    #
    # The serialization/deserialization of the generated completions from the Bash process to the Nushell process is a
    # bit naive. Consider unhandled cases.
    $result.stdout | split row (char newline) | where $it != '' | sort | uniq
}

# This function is meant for debugging the external completer closure. See the related note inside the closure.
export def bash-complete [spans] {
    do $bash_completer $spans
}

$env.config.completions.external = {
  enable: true
  completer: $bash_completer
}

# Activate a default OpenJDK, Node.js, etc.
#
# Oddly, at this point, $env.PATH is the typical colon-delimited value that we are familiar with in most environments.
# In Nushell, $env.PATH is supposed to be a list but I guess we are too early in the bootstrapping process? Anyway, we
# have to parse it into a list. Let' take the naive approach (after some quick searching I didn't find a better way)
# and split on ":" (or are colons not allowed anywhere in paths and files across all systems?).
def --env activate-defaults [] {
    let default_java = 21
    let default_node = "20"
    let default_postgres = "16"

    let split_path = $env.PATH | split row ":"
    $env.PATH = $split_path
    try { activate-my-open-jdk $default_java } catch { print "(warn) A default OpenJDK was not activated." }
    try { activate-my-node $default_node } catch { print "(warn) A default Node.js was not activated." }
    try { activate-postgres $default_postgres } catch { print "(warn) A default Postgres was not activated." }
}

activate-defaults

# Discover keg installations of OpenJDK and make them available (i.e. "advertise") as version-specific "JAVA_HOME"
# environment variables.
#
# For example, for a Java 17 OpenJDK keg installed at "/opt/homebrew/opt/my-open-jdk@17" then set the environment
# variable "JAVA_HOME_17" to that path.
def --env advertise-installed-open-jdks [] -> nothing {
    for keg in (my-open-jdk-kegs) {
        let java_x_home = $"JAVA_($keg.java_version)_HOME"
        load-env { $java_x_home: $keg.jdk_home_dir }
    }
}

advertise-installed-open-jdks

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
#   │ 0 │ /Users/dave/repos/personal/my-config         │
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
#    is-git-project-dirty ~/repos/personal/my-config        # true (a.k.a. "dirty". There are uncommitted changes.)
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

  $shell_snippets | input list --display content --fuzzy 'Execute command:'
    | if ($in | is-empty) {
        # If the user abandoned the selection, then don't do anything.
        return
      } else { $in }
    | get content | commandline edit $in
}

export alias rfr = run-from-readme

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

# 'mfzf' is a Nushell command and wrapper over the 'my-fuzzy-finder' program.
#
# 'mfzf' adds the Nushell experience to 'my-fuzzy-finder' by supporting structured input and output and commandline
# completions.
#
# For input tables, 'mfzf' will extract a "filter column" from the input table and pass the values as lines into
# 'my-fuzzy-finder'. 'mfzf' will use the first table column as the filter column, or it will use the one specified by
# the optional "--filter-column" flag. After you've selected a row, 'mfzf' will then convert the JSON object returned by
# 'my-fuzzy-finder' into a record and return that.
#
# For example, fuzzy find files in the current directory:
#
#   $ ls | mfzf
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
#   $ ls | mfzf --filter-column type
#   $ ls | mfzf -f size
#   $ ls | mfzf -f modified
#
# 'mfzf' also supports lists as input. So, for example, you can do:
#
#   $ glob */** | mfzf
#
export def mfzf [--filter-column (-f): string] [list<string> -> string, table -> record] {
    which my-fuzzy-finder | if ($in | is-empty) {
        error make --unspanned { msg: "The 'my-fuzzy-finder' program is not installed." }
    }

    let _in = $in
    if ($_in | is-empty) {
        print "(mfzf) No input"
        return
    }

    let in_type = if ($_in | describe | str starts-with table) {
        "table"
    } else if ($_in | describe | str starts-with list) {
        "list"
    } else {
        error make --unspanned { msg: "Unsupported input type." }
    }

    let lines = match $in_type {
        "table" => {
            let _filter_column = if ($filter_column | is-not-empty) { $filter_column } else { $_in | columns | first }
            $_in | get $_filter_column | str join (char newline)
        }
        "list" => {
            $_in | str join (char newline)
        }
    }

    let result = $lines | my-fuzzy-finder --json-out | complete

    match $result.exit_code {
        0 => {
            # Success
        }
        1 => {
            # This is a normal case. When there are no matches, 'my-fuzzy-finder' exits with a 1 status code. This is
            # the same behavior as 'fzf'.
            print "(mfzf) No match"
            return
        }
        130 => {
            # This is a normal case. When the user abandons the selection, 'my-fuzzy-finder' exits with a 130 status
            # code. This is the same behavior as 'fzf'.
            print "(mfzf) No selection"
            return
        }
        _ => {
            error make --unspanned { msg: "Something went wrong. Received an unexpected status code from 'my-fuzzy-finder'." }
        }
    }

    let output_record = ($result.stdout | from json)
    return ($_in | get $output_record.index)
}
