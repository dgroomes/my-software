use zdu.nu err

# WARNING: Mostly AI generated. The UX is carefully considered, and I've pared down the complexity.

# Read the weekly ChatGPT subscription quota exposed by Codex.
# Requires the Codex CLI signed in with ChatGPT (`codex login`).
#
# Example:
#   > gpt-usage
#   Weekly · resets in 3d 4h
#   ███████████████████░ 95% left 🟢 Plenty
export def gpt-usage [] {
    let result = read-usage
    # We only expect a codex bucket, but OpenAI may change this over time or
    # return different buckets depending on the subscription type.
    mut bucket = $result.rateLimits?
    for entry in ($result.rateLimitsByLimitId? | default {} | transpose id bucket) {
        if $entry.id == "codex" {
            $bucket = $entry.bucket
        } else {
            print --stderr $"Warning: ignoring quota bucket '($entry.id)'. Using codex only."
        }
    }
    if $bucket.limitId? != "codex" {
        err "Codex returned no codex quota bucket."
    }
    if $bucket.secondary? != null {
        print --stderr "Warning: ignoring an additional quota window. Using the primary window only."
    }
    let window = $bucket.primary?
    if $window == null {
        err "Codex returned no primary quota window."
    }

    let duration = if $window.windowDurationMins? != null {
        $window.windowDurationMins * 1min
    }
    let used_percent = $window.usedPercent?
    let remaining_percent = if $used_percent != null {
        100 - $used_percent
    }
    let resets_at = if $window.resetsAt? != null {
        let nanoseconds = $window.resetsAt * 1_000_000_000
        $nanoseconds | into datetime | date to-timezone local
    }

    let usage = {
        duration: $duration
        used_percent: $used_percent
        remaining_percent: $remaining_percent
        resets_at: $resets_at
    }
    format-usage $usage (date now)
}

def format-usage [usage: record, now: datetime] {
    let window = if $usage.duration? == 1wk {
        "Weekly"
    } else if $usage.duration? == null {
        "Usage"
    } else {
        $"($usage.duration) window"
    }
    let reset = format-reset $usage.resets_at? $now
    let remaining = $usage.remaining_percent?
    let meter = if $remaining == null {
        "???????????????????? ?% left ❔ Unknown"
    } else {
        let filled = $remaining / 5 | math floor | into int
        let full = "" | fill --character "█" --width $filled
        let empty = "" | fill --character "░" --width (20 - $filled)
        let status = if $remaining == 100 {
            "🔋 Full"
        } else if $remaining >= 60 {
            "🟢 Plenty"
        } else if $remaining >= 30 {
            "🟡 Steady"
        } else if $remaining > 0 {
            "🟠 Low"
        } else {
            "🪫 Empty"
        }
        $"($full)($empty) ($remaining)% left ($status)"
    }
    $"($window) · ($reset)\n($meter)"
}

def format-reset [resets_at: any, now: datetime] {
    if $resets_at == null { return "reset unknown" }
    let remaining = $resets_at - $now
    if $remaining <= 0sec { return "reset due" }

    let days = $remaining / 1day | math floor | into int
    let hours = ($remaining mod 1day) / 1hr | math floor | into int
    let minutes = ($remaining mod 1hr) / 1min | math floor | into int
    if $days > 0 {
        $"resets in ($days)d ($hours)h"
    } else if $hours > 0 {
        $"resets in ($hours)h ($minutes)m"
    } else if $minutes > 0 {
        $"resets in ($minutes)m"
    } else {
        "resets in <1m"
    }
}

# Call the documented Codex app-server RPC using the CLI's existing login.
# https://learn.chatgpt.com/docs/app-server
# A temporary server handles one request, with a five-second total timeout.
def read-usage [] {
    if (which codex | is-empty) {
        err "Install the Codex CLI and sign in with `codex login` first."
    }

    let parent = job id
    let deadline = (date now) + 5sec
    let stderr = mktemp
    let worker = job spawn --description "gpt-usage" {
        let tag = job id
        try {
            # Keep stdin open between requests. `to text` streams one JSON line
            # per mailbox message; closing stdin early can discard the RPC reply.
            generate {|state| {out: (job recv | to json --raw), next: 0}} 0
            | to text
            | ^codex app-server --listen stdio:// e> $stderr
            | lines
            | each {|line|
                let message = $line | from json
                if $message.id? != null {
                    $message | job send $parent --tag $tag
                }
            }
            | ignore
            {transportError: "Codex app-server exited before completing the query."}
            | job send $parent --tag $tag
        } catch {|failure|
            {transportError: $failure.msg} | job send $parent --tag $tag
        }
    }

    let result = try {
        {
            id: 1
            method: initialize
            params: {clientInfo: {name: chat_gpt_usage, version: "0.1.0"}}
        } | job send $worker
        receive $worker 1 $deadline | ignore
        {method: initialized} | job send $worker
        {id: 2, method: "account/rateLimits/read"} | job send $worker
        receive $worker 2 $deadline
    } catch {|failure|
        try { job kill $worker }
        let details = open --raw $stderr | str trim
        rm $stderr
        let message = $"Unable to read ChatGPT usage: ($failure.msg)"
        err ([$message $details] | where {|part| $part != "" } | str join (char newline))
    }
    try { job kill $worker }
    rm $stderr

    $result
}

def receive [worker: int, id: int, deadline: datetime] {
    let remaining = $deadline - (date now)
    if $remaining <= 0sec {
        err "Timed out waiting for Codex app-server."
    }
    let message = job recv --tag $worker --timeout $remaining
    if $message.transportError? != null {
        err $message.transportError
    }
    if $message.error? != null {
        err $"($message.error.message) Check your ChatGPT sign-in with `codex login status`."
    }
    if $message.id? != $id {
        err "Codex returned an unexpected response ID."
    }
    $message.result
}
