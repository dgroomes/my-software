# I'm still zeroing in on the ideal sourcing strategy. I would prefer the "sourcing from a directory" approach, but this
# is not possible. The Nushell docs point this out: https://www.nushell.sh/book/modules.html#dumping-files-into-directory
# Let's let 'core.nu' go first. The rest let's organize alphabetically.
source ([$nu.default-config-dir core.nu] | path join)

source ([$nu.default-config-dir atuin.nu] | path join)
source ([$nu.default-config-dir misc.nu] | path join)
source ([$nu.default-config-dir node.nu] | path join)
source ([$nu.default-config-dir nu-scripts-sourcer.nu] | path join)
source ([$nu.default-config-dir open-jdk.nu] | path join)
source ([$nu.default-config-dir postgres.nu] | path join)
source ([$nu.default-config-dir starship.nu] | path join)
source ([$nu.default-config-dir zoxide.nu] | path join)

# I don't really understand the essential coverage, or purpose, of the directories added to the PATH by the macOS
# "/usr/libexec/path_helper" tool. But, at the least, I know it adds "/usr/local/bin" to the PATH and I need that.
# I'm not going to dig into this further. I just vaguely know about /etc/paths and /etc/paths.d and today I learned
# or maybe re-learned about /etc/profile and /etc/bashrc.
$env.PATH = ($env.PATH | append "/usr/local/bin")

$env.config.buffer_editor = "subl"

def repos [] {
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

export alias cdr = cd-repo

# Copy the last command to the clipboard
export def cp-last-cmd [] {
    history | last 2 | first | get command | pbcopy
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

def coalesce [...vals] {
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
def --env new-subject [subject?] {
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

# Define an external completer (https://www.nushell.sh/cookbook/external_completers.html) based on Bash and the
# 'bash-completion' library (https://github.com/scop/bash-completion).
let bash_completer =  { |spans|
    let bash_path = which bash | if ($in | is-empty) {
        # Note: you won't see this message when the closure is invoked by Nushell's external completers machinery.
        # Silencing (or "swallowing") the output of a rogue completer is designed as a feature. Totally fair, but that
        # makes debugging external completer closures difficult. See the 'bash-complete' function which is designed to
        # wrap this closure, which let's you see output like this normally. I didn't have any luck with the standard
        # library logger or the internal logs (e.g. `nu --log-level debug`) either.
        print "Bash is not installed. The Bash completer will not be registered."
        return
    } else {
       $in.0.path
    }

    let one_shot_bash_completion_script = [$nu.default-config-dir one-shot-bash-completion.bash] | path join | if ($in | path exists)  {
        $in | path expand
    } else {
        print "The one-shot Bash completion script does not exist. No completions will be available."
        return
    }

    let line = $spans | str join " "

    # We set up a controlled environment so we have a better chance to debug completion problems. In particular, we are
    # exercising control over the "search order" that 'bash-completion' uses to find completion definitions. For more
    # context, see this section of the 'bash-completion' README: https://github.com/scop/bash-completion/blob/07605cb3e0a3aca8963401c8f7a8e7ee42dbc399/README.md?plain=1#L333
    mut env_vars = {
        BASH_COMPLETION_INSTALLATION_DIR: /opt/homebrew/opt/bash-completion@2
        BASH_COMPLETION_USER_DIR: ([$env.HOME .local/share/bash-completion] | path join)
        BASH_COMPLETION_COMPAT_DIR: /disable-legacy-bash-completions-by-pointing-to-a-dir-that-does-not-exist
        XDG_DATA_DIRS: /opt/homebrew/share
    }

    mut env_vars_path = []

    # Homebrew's 'brew' command comes with an odd implementation of its completion scripts. It relies on the
    # "HOMEBREW_" environment variables that are set up in the 'brew shellenv' command. See https://github.com/Homebrew/brew/blob/e2b2582151d451d078e9df35a23eef00f4d308b3/completions/bash/brew#L111
    # And it relies on grep.
    #
    # So, let's pass the 'HOMEBREW_REPOSITORY' environment variable through and let's make sure 'grep' is on the PATH.
    if ($env.HOMEBREW_REPOSITORY? | is-not-empty) {
        $env_vars = $env_vars | insert HOMEBREW_REPOSITORY $env.HOMEBREW_REPOSITORY
    }

    $env_vars_path = ($env_vars_path | append (which grep | $in.0?.path | path dirname))

    # In its completion lookup logic, 'bash-completion' considers the full path of the command being completed.
    # For example, if the command is 'pipx', then 'bash-completion' tries to resolve ' pipx' to a location on the PATH
    # by issuing a 'type -P -- pipx' command (https://github.com/scop/bash-completion/blob/07605cb3e0a3aca8963401c8f7a8e7ee42dbc399/bash_completion#L3158).
    # It's rare that this is needed to make completions work, but I found it was needed for 'pipx', at least. Do the
    # 'pipx' completions definitions code to an absolute path? Seems like a strange implementation. I'd be curious to
    # learn more.
    #
    # So, we can't isolate the PATH entirely from the one-shot Bash completion script. Let's create a PATH that just
    # contains the directory of the command being completed.
    $env_vars_path = ($env_vars_path | append ($spans.0? | which $in | get path | path dirname))

    let path = ($env_vars_path | str join ":")
    $env_vars = ($env_vars | insert PATH $path)

    # Turn the environment variables into "KEY=VALUE" strings in preparation for the 'env' command.
    mut env_var_args = $env_vars | items { |key, value| [$key "=" $value] | str join }

    # Note: we are using "$bash_path" which is the absolute path to the Bash executable of the Bash that's installed
    # via Homebrew. If we were to instead use "bash", then it would resolve to the "bash" that's installed by macOS
    # which is too old to work with 'bash-completion'.
    let result = env -i ...$env_var_args $bash_path --noprofile $one_shot_bash_completion_script $line | complete

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
export def bash-complete [spans: list<string>] {
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
            print "(fz) No selection"
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
def --wrapped fd [...args] {
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

# By convention, I put 'do.nu' scripts in projects and this lets me compress and automate my workflow. This command
# activates the 'do.nu' script as a module using Nushell's *overlays*. Because of Nushell's parse-evaluate model, this
# actually pretty difficult to do, so we can abuse Nushell hooks to do this.
#
# A feature of 'do-activate' is that the 'do.nu' script will be continually reloaded between commands in the shell.
export def --env "do activate" [] {
    if not ("do.nu" | path exists) {
        error make --unspanned { msg: "No 'do.nu' script found." }
    }

    if "DO_MODULE_DIR" in $env {
        error make --unspanned { msg: "Detected the 'DO_MODULE_DIR' environment variable. A 'do.nu' script was previously activated." }
    }

    # The DO_MODULE_DIR trick is necessary because Nushell doesn't support the special `$env.FILE_PWD` environment
    # variable in modules (see <https://github.com/nushell/nushell/issues/9776>). So, we've invented a convention of
    # using a DO_MODULE_DIR environment variable to represent the project directory. The 'do.nu' script can use this
    # to fix commands and file references to the right path.
    $env.DO_MODULE_DIR = (pwd)

    # Here is the tricky part. Register a pre_prompt hook that will load the 'do.nu' script and then the hook will
    # erase itself. I have details about this pattern in my nushell-playground repository: https://github.com/dgroomes/nushell-playground/blob/b505270046fd2c774927749333e67707073ad62d/hooks.nu#L72
    const SNIPPET = r#'
# ERASE ME
overlay use --prefix do.nu
let hooks = $env.config.hooks.pre_prompt
let filtered = $hooks | where ($it | describe) != "string" or $it !~ "# ERASE ME"
$env.config.hooks.pre_prompt = $filtered
'#

    $env.config = ($env.config | upsert hooks.pre_prompt {
        default [] | append $SNIPPET
    })
}

export alias da = do activate
