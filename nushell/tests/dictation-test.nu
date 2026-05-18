use std/assert
source ../scripts/dictation.nu

const SAMPLE_FFMPEG_OUTPUT = '
ffmpeg version 8.1.1 Copyright (c) 2000-2026 the FFmpeg developers
[AVFoundation indev @ 0x926c10140] AVFoundation video devices:
[AVFoundation indev @ 0x926c10140] [0] MacBook Pro Camera
[AVFoundation indev @ 0x926c10140] AVFoundation audio devices:
[AVFoundation indev @ 0x926c10140] [0] MacBook Pro Microphone
[AVFoundation indev @ 0x926c10140] [1] Studio Display Microphone
[in#0 @ 0x926c10000] Error opening input: Input/output error
'

def main [] {
    # I have a branch that uses the https://github.com/vyadh/nutest framework. I've decided I want to use that. Consider
    # how to rewrite dictation-test.nu to use that framework so we can have a little less boilerplate.
    let test_commands = (
        scope commands
        | where ($it.type == "custom") and ($it.name | str starts-with "test ")
        | get name
        | each { |test| [$"print 'Running test: ($test)'", $test] }
        | flatten
        | str join "; "
    )

    nu --commands $"source ($env.CURRENT_FILE); ($test_commands)"
}

def "test parse-audio-devices" [] {
    let devices = $SAMPLE_FFMPEG_OUTPUT | parse-audio-devices

    assert equal $devices [
        { index: 0 name: "MacBook Pro Microphone" }
        { index: 1 name: "Studio Display Microphone" }
    ]
}
