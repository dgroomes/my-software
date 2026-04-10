use zdu.nu err
use my-git-lib.nu *

# Warning: unedited AI output.


# My Git helpers.
export def my-git [] {
    help my-git
}

# Open the browser to the Git hosting page for the current checked out ref.
#
# Think of this as a simpler, more predictable cousin of 'gh browse'. It solves the same basic problem, but it derives
# the browser URL directly from the Git remote URL instead of consulting GitHub-specific environment like 'GH_HOST'.
# That means the selected remote fully determines the destination.
#
# If you pass a remote name, that remote is used.
# If you omit the remote name and the repository has exactly one remote, that remote is used automatically.
# If you omit the remote name and the repository has zero or multiple remotes, the command errors and tells you to be
# explicit.
#
# The current ref is resolved in this order:
#   1. the current branch name
#   2. an exactly matching tag name, if HEAD is detached at a tag
#   3. the full commit SHA
#
# Supported remote URL styles:
#   - https://github.com/dgroomes/my-software.git
#   - git@github.com:dgroomes/my-software.git
#
# Resulting URLs look like:
#   - https://github.com/dgroomes/my-software/tree/main
#   - https://github.com/dgroomes/my-software/tree/v1.2.3
#   - https://github.com/dgroomes/my-software/tree/0123456789abcdef
#
# @example "Use the only configured remote" { my-git ui }
# @example "Use a specific remote" { my-git ui origin }
# @example "Resolve an SCP-style SSH remote to an HTTPS browser URL" { my-git ui upstream }
# @example "Detached HEAD at a tag opens a tag-based tree URL" { my-git ui origin }
# @example "Detached HEAD without a tag opens a commit-SHA-based tree URL" { my-git ui origin }
export def "my-git ui" [
    remote?: string@my-git-remotes
] {
    let remote = resolve-remote $remote
    let remote_url = git-remote-url $remote
    let repo_url = remote-url-to-web-url $remote_url
    let ref = current-ref
    let url = $"($repo_url)/tree/($ref)"

    ^open $url
}

def my-git-remotes []: nothing -> list<string> {
    let result = git remote | complete

    if ($result.exit_code != 0) {
        return []
    }

    $result.stdout | lines | where { |it| $it | is-not-empty }
}

def resolve-remote [remote?: string]: nothing -> string {
    resolve-remote-from-list (my-git-remotes) $remote
}

def git-remote-url [remote: string]: nothing -> string {
    let result = git remote get-url $remote | complete

    if ($result.exit_code != 0) {
        if ($result.stderr | str contains "fatal: not a git repository") {
            err "This is not a Git repository."
        }

        if ($result.stderr | str contains "No such remote") {
            err $"No Git remote named '($remote)' was found."
        }

        err $"Unexpected response from 'git remote get-url'.\n($result.stderr)"
    }

    $result.stdout | str trim
}

def current-ref []: nothing -> string {
    let branch_result = git branch --show-current | complete

    if ($branch_result.exit_code != 0) {
        if ($branch_result.stderr | str contains "fatal: not a git repository") {
            err "This is not a Git repository."
        }

        err $"Unexpected response from 'git branch --show-current'.\n($branch_result.stderr)"
    }

    let branch = $branch_result.stdout | str trim
    if ($branch | is-not-empty) {
        return $branch
    }

    let tag_result = git describe --tags --exact-match | complete
    if ($tag_result.exit_code == 0) {
        let tag = $tag_result.stdout | str trim
        if ($tag | is-not-empty) {
            return $tag
        }
    }

    let head_result = git rev-parse HEAD | complete
    if ($head_result.exit_code != 0) {
        err $"Unexpected response from 'git rev-parse HEAD'.\n($head_result.stderr)"
    }

    $head_result.stdout | str trim
}

