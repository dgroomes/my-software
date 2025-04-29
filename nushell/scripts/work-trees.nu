use zdu.nu err
use zdu.nu compress-home

# Commands for working with Git working trees.
#
# Let's refer to the directory containing the '.git' directory as the root wt. I think the root wt should have the default branch checked out. Seems redundant to force there to
# be a wt directory for the default branch. Extra directories and files are noise. Also, my aim with this is not to
# isolate this wt from "doing real work". I'll still use it to do plenty of git commands as I wrangle, explore, and fix
# git things. But we open a degree of freedom with a convention of a "working tree per idea" workflow. Comes at a cost.
# I'm having just enough friction that I want to try it. Plus, Git is FAST for this kind of thing and storage is fast
# and cheap.
#
# I'm really not sure the best conventional directory layout to have the wts. One strong consensus is to not try to put
# your wts in the same directory containing the '.git' directory. While technically possible, you have to configure your
# .gitignore correctly and also external tooling (IDEs etc) will get confused. I think I'm going to do a sibling
# directory thing with dot separators.
#
# So by way of example, let's use 'my-software'. Here is my vision of the directory structure:
#
#   ~/repos/personal/my-software                    Will usually have the default branch checked out, but could be anything. Detached, something else...
#   ~/repos/personal/my-software.my-node-launcher   'my-node-launcher' branch checked out. I'm working on that and it's long lived enough.
#   ~/repos/personal/my-software.jdk-24             'jdk-24' branch checked out. I'm messing with my Homebrew formulas, for example.
#   ~/repos/personal/my-software.mcp                'mcp' branch checked out. I'm messing with Model Context Protocol and don't know where I'm going yet.
#
# One thing I'm excited about with this is just the hassle savings of not doing 'git stash' (or the equivalent of
# committing a 'wip' commit) and later undoing it. And also the time IDE savings of not re-indexing and/or screwing up
# the index.
#
# One thing that will be a new problem is that .gitignore'd secret files will have to be copied over as needed. I could
# script something out. Not sure how big of a problem this will be in practice.
export def gwt [] {
    help gwt
}

# Get the working trees of the currently scoped Git repository.
#
# For example:
#
#     ╭───┬─────────────────────────────────────┬──────────┬─────────────────────╮
#     │ # │                path                 │   head   │       branch        │
#     ├───┼─────────────────────────────────────┼──────────┼─────────────────────┤
#     │ 0 │ ~/repos/opensource/iceberg          │ 22d194f5 │ refs/heads/main     │
#     │ 1 │ ~/repos/opensource/iceberg.detached │ 01fe380d │                     │
#     │ 2 │ ~/repos/opensource/iceberg.scratch  │ 22d194f5 │ refs/heads/scratch  │
#     │ 3 │ ~/repos/opensource/iceberg.scratch2 │ 22d194f5 │ refs/heads/scratch2 │
#     ╰───┴─────────────────────────────────────┴──────────┴─────────────────────╯
#
export def "gwt ls" [] {
    let r = git worktree list --porcelain | complete

    if ($r.exit_code != 0) {
        if ($r.stderr | str contains "fatal: not a git repository") {
            err "This is not a Git repository."
            return
        }
        err $"Unexpected response from 'git worktree' command. \n($r.stderr)"
        return
    }

    # The output will look something like the following.
    #
    #     $ git worktree list --porcelain
    #     worktree /Users/me/repos/iceberg
    #     HEAD 22d194f5d685fdf5bec17c6bcc92a69db4ae4957
    #     branch refs/heads/main
    #
    #     worktree /Users/me/repos/iceberg.detached
    #     HEAD 01fe380d455949abb49ebfecd9509afce8764fae
    #     detached
    #
    #     worktree /Users/me/repos/iceberg.scratch
    #     HEAD 22d194f5d685fdf5bec17c6bcc92a69db4ae4957
    #     branch refs/heads/scratch
    #
    #     worktree /Users/me/repos/iceberg.scratch2
    #     HEAD 22d194f5d685fdf5bec17c6bcc92a69db4ae4957
    #     branch refs/heads/scratch2
    #     locked
    #
    # Notice the following things:
    #     - The first line is always 'worktree '
    #     - The second line is always 'HEAD '
    #     - The third line is always either 'branch ' or 'detached ''
    #     - There may be more lines for things like 'locked' (not sure what that is).
    #     - There is a trailing newline (not clear from the example output)

    let lg = $r.stdout | lines | split list '' | drop 1


    $lg | each { from-lines $in }
}

def from-lines [l] {
    let path = $l.0 | str replace 'worktree ' '' | compress-home
    let head = $l.1 | str replace 'HEAD ' '' | str substring 0..7
    mut r = { path: $path }

    let branch = if ($l.2 | str starts-with 'branch ') {
        $l.2 | str replace 'branch ' ''
    } else {
        null
    }

    return {
        path: $path
        head: $head
        branch: $branch
    }
}

# Switch to a working tree within the currently scoped Git repository.
export def --env "gwt switch" [
    name: string@gwt-names # The name of the directory containing the working tree to switch to.
] {

    let f = gwt ls | where (($it.path | path basename) == $name)

    if ($f | is-empty) {
        err $"No working tree found for '($name)'"
    }

    cd $f.0.path
}

def "gwt-names" [] {
    gwt ls | each { $in.path | path basename }
}

# Add a new working tree and switch into it.
#
# There are multiple overloads of the 'git' command for creating a new working tree but there's one that I'll use the
# most: creating a working tree and a branch at the same time. I'll just support that for now.
export def --env "gwt add" [
    --name (-n): string
] {
    let root_wt = gwt ls | sort-by { $in.path | str length } | $in.0.path | path expand
    let repo = $root_wt | path basename
    let wtn = $"($repo).($name)"
    let wtd = [($root_wt | path dirname) $wtn] | path join

    let r = git worktree add -b $name $wtd | complete

    if ($r.exit_code != 0) {
        err $"Unexpected response from 'git worktree add' command. \n($r.stderr)"
        return
    }

    cd $wtd
}

# I'm not adding a 'gwt rm' because 'git worktree remove' has autocompletion. The only convenience of adding a custom
# command would be the consistency of the 'gwt' name with the other commands. This is an important tenet though... don't
# lose the plot. The goal is never to hide the underlying/important commands. 'git worktree remove' is perfectly fine.
