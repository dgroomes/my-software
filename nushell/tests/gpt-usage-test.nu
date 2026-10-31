use std/testing *
use std/assert
source ../scripts/gpt-usage-module.nu

const NOW = 2026-10-31T12:00:00Z

def snapshot [remaining: any, reset: any = "2026-11-03T16:00:00Z"] {
    {duration: 1wk, remaining_percent: $remaining, resets_at: (if $reset != null { $reset | into datetime })}
}

@test
def "full allowance fills the bar" [] {
    assert equal (format-usage (snapshot 100) $NOW) "Weekly · resets in 3d 4h\n████████████████████ 100% left 🔋 Full"
}

@test
def "plenty of allowance" [] {
    assert equal (format-usage (snapshot 75) $NOW) "Weekly · resets in 3d 4h\n███████████████░░░░░ 75% left 🟢 Plenty"
}

@test
def "half allowance fills half the bar" [] {
    assert equal (format-usage (snapshot 50) $NOW) "Weekly · resets in 3d 4h\n██████████░░░░░░░░░░ 50% left 🟡 Steady"
}

@test
def "low allowance is easy to spot" [] {
    assert equal (format-usage (snapshot 10) $NOW) "Weekly · resets in 3d 4h\n██░░░░░░░░░░░░░░░░░░ 10% left 🟠 Low"
}

@test
def "empty allowance has an empty bar" [] {
    assert equal (format-usage (snapshot 0) $NOW) "Weekly · resets in 3d 4h\n░░░░░░░░░░░░░░░░░░░░ 0% left 🪫 Empty"
}

@test
def "missing allowance is unknown rather than empty" [] {
    assert equal (format-usage (snapshot null null) $NOW) "Weekly · reset unknown\n???????????????????? ?% left ❔ Unknown"
}

@test
def "status thresholds and bar width" [] {
    for case in [
        {remaining: 1, status: "🟠 Low"}
        {remaining: 29, status: "🟠 Low"}
        {remaining: 30, status: "🟡 Steady"}
        {remaining: 59, status: "🟡 Steady"}
        {remaining: 60, status: "🟢 Plenty"}
        {remaining: 99, status: "🟢 Plenty"}
    ] {
        let line = format-usage (snapshot $case.remaining) $NOW | lines | last
        assert ($line | str ends-with $case.status)
        assert equal ($line | split row " " | first | str length --grapheme-clusters) 20
    }
}

@test
def "reset countdown gets shorter near the reset" [] {
    assert ((format-usage (snapshot 50 ($NOW + 2hr + 15min)) $NOW) | str starts-with "Weekly · resets in 2h 15m\n")
    assert ((format-usage (snapshot 50 ($NOW + 15min)) $NOW) | str starts-with "Weekly · resets in 15m\n")
    assert ((format-usage (snapshot 50 ($NOW + 30sec)) $NOW) | str starts-with "Weekly · resets in <1m\n")
    assert ((format-usage (snapshot 50 $NOW) $NOW) | str starts-with "Weekly · reset due\n")
    assert ((format-usage (snapshot 50 ($NOW - 1min)) $NOW) | str starts-with "Weekly · reset due\n")
}

@test
def "unexpected window duration stays truthful" [] {
    let usage = snapshot 50 | update duration 5hr
    assert ((format-usage $usage $NOW) | str starts-with "5hr window · ")
}
