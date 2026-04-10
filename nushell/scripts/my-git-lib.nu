use zdu.nu err

# Warning: unedited AI output.

export def resolve-remote-from-list [remotes: list<string>, remote?: string]: nothing -> string {
    if ($remote | is-not-empty) {
        return $remote
    }

    if ($remotes | is-empty) {
        err "This Git repository has no remotes configured."
    }

    if ($remotes | length) == 1 {
        return $remotes.0
    }

    err $"This Git repository has multiple remotes configured: ($remotes | str join ', '). Pass an explicit remote name to 'my-git ui'."
}

export def remote-url-to-web-url [remote_url: string]: nothing -> string {
    let https = $remote_url | parse --regex '^(?<scheme>https?)://(?:[^@/]+@)?(?<host>[^/]+)/(?<path>.+)$'
    if ($https | is-not-empty) {
        return (build-web-url $https.0.scheme $https.0.host $https.0.path)
    }

    if ($remote_url | str contains '://') {
        err $"Unsupported Git remote URL: '($remote_url)'"
    }

    let scp = $remote_url | parse --regex '^(?:[^@]+@)?(?<host>[^:]+):(?<path>.+)$'
    if ($scp | is-not-empty) {
        return (build-web-url "https" $scp.0.host $scp.0.path)
    }

    err $"Unsupported Git remote URL: '($remote_url)'"
}

def build-web-url [scheme: string, host: string, repository_path: string]: nothing -> string {
    let normalized_path = (
        $repository_path
        | str trim
        | str replace --regex '^/' ''
        | str replace --regex '\.git/?$' ''
        | str replace --regex '/+$' ''
    )

    $"($scheme)://($host)/($normalized_path)"
}
