# I'm still zeroing in on the ideal sourcing strategy. I would prefer the "sourcing from a directory" approach, but this
 # is not possible. The Nushell docs point this out: https://www.nushell.sh/book/modules.html#dumping-files-into-directory
source ([$nu.default-config-dir core.nu] | path join)
source ([$nu.default-config-dir starship.nu] | path join)
source ([$nu.default-config-dir atuin.nu] | path join)
source ([$nu.default-config-dir open-jdk.nu] | path join)
source ([$nu.default-config-dir nu-scripts-sourcer.nu] | path join)

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

export alias gw = ./gradlew

# fnm is basically a drop-in replacement for nvm. We can alias nvm to it.
export alias nvm = fnm

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

    # Note: the `--noprofile` flag is important. I've designed the one-shot Bash completion script to have everything
    # it needs to bootstrap itself. I considered using "env -i" as well but decided it's not necessary.
    let result = bash --noprofile $one_shot_bash_completion_script $line | complete
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

# Activate a default OpenJDK.
#
# Oddly, at this point, $env.PATH is the typical colon-delimited value that we are familiar with in most environments.
# In Nushell, $env.PATH is supposed to be a list but I guess we are too early in the bootstrapping process? Anyway, we
# have to parse it into a list. Let' take the naive approach (after some quick searching I didn't find a better way)
# and split on ":" (or are colons not allowed anywhere in paths and files across all systems?).
def --env activate-default-open-jdk [version: string] {
    let split_path = $env.PATH | split row ":"
    $env.PATH = $split_path
    try { activate-my-open-jdk $version } catch { print "(warn) A default OpenJDK was not activated." }
}

activate-default-open-jdk 21

alias use-java = activate-my-open-jdk

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
