# Dictation workflow: record from a macOS AVFoundation microphone with ffmpeg, then transcribe with OpenAI.

use zdu.nu err

const TRANSCRIPTIONS_URL = "https://api.openai.com/v1/audio/transcriptions"
const TRANSCRIPTIONS_MODEL = "gpt-4o-transcribe"

# Dictate into a system microphone and transcribe with OpenAI.
#
# This is my attempt at making an MVP alternative to my habit of dictating into the text box in ChatGPT and copying the
# output.
#
# An important improvement in 'dictate' over the ChatGPT trick is that if the transcription errors (which it sometimes
# does in ChatGPT), then the audio file is not also lost, and I can re-submit it.
#
# Over time, I'll make some more improvements, like including a prompt of fequently mis-transcribed words to reduce the
# word error rate (WER).
#
export def --env dictate []: nothing -> record {
    let dictation_dir = "~/.my/dictation" | path expand
    mkdir $dictation_dir

    let recording_path = [$dictation_dir recording.m4a] | path join
    let log_path = [$dictation_dir log.txt] | path join

    # Delete previous recording and logs
    rm -f $recording_path $log_path

    let started = date now
    let action = record-audio $recording_path $log_path

    if $action == "cancel" {
        rm $recording_path
        return
    }

    let stopped = date now
    let recording_duration = $stopped - $started
    let recording_size = ls $recording_path | first | get size

    let response = transcribe $recording_path

    return {
        recording_duration: $recording_duration
        recording_size: $recording_size
        transcription_length: ($response.text | str length)
        transcription_text: $response.text
    }
}

# Kick off ffmpeg as a job to record audio. This awaits an "Enter/Esc" input from the user to indicate when to stop.
def record-audio [audio_path log_path] {
    let device = audio-devices | choose-mic

    let opts = [
        -hide_banner
        -nostdin
        -y
        -f avfoundation
        -i $":($device.index)"
        -vn
        -c:a
        aac
        $audio_path
    ]

    let job_id = job spawn --description "dictation recording" {
        ^ffmpeg ...$opts o+e> $log_path
    }

    print $"🔴 Recording for dictation using \"($device.name)\" ..."
    print ""
    print $"[Enter] Send for transcription      /      [Esc] Cancel"

    mut action = "send"
    loop {
        let event = input listen --types [key]

        if ($event.code? == "enter") {
            $action = "send"
            break
        }

        if ($event.code? in [esc escape]) {
            $action = "cancel"
            break
        }
    }

    # ffmpeg needs a graceful interrupt so it can finalize the m4a container. Nushell's `job kill` force-kills the
    # child process, so use SIGINT first and keep `job kill` only as the timeout fallback.
    let pids = job list | where { |job| $job.id == $job_id } | first | get pids
    for pid in $pids {
        kill --signal 2 --quiet $pid
    }

    # SIGINT only asks ffmpeg to stop. Wait briefly for it to flush audio and write the final m4a trailer before falling
    # back to a force kill.
    for _ in 0..40 {
        if ((job list | where { |job| $job.id == $job_id }) | is-empty) {
            return $action
        }

        sleep 100ms
    }

    # Last resort: stop the job even if ffmpeg did not handle SIGINT cleanly.
    job kill $job_id

    $action
}

def --env dictate-api-key [] {
    mut key = $env.DICTATE_OAI_API_KEY?

    if ($key == null) or ($key | is-empty) {
        print "Set OpenAI API key for dictation:"
        $key = (input --suppress-output)
        $env.DICTATE_OAI_API_KEY = $key
    }

    $key
}

# Do I need this?
def curl-config-quote []: string -> string {
    $in
        | str replace --all '\' '\\'
        | str replace --all '"' '\"'
        | str replace --all (char cr) '\r'
        | str replace --all (char newline) '\n'
}

# Do I need this?
def curl-config-line [name: string, value: string]: nothing -> string {
    $"($name) = \"($value | curl-config-quote)\""
}

# Transcribe the given audio file with OpenAI's trascription APIs
def --env transcribe [audio_path: string] {
    let key = dictate-api-key
    mut config_lines = [
        (curl-config-line "url" $TRANSCRIPTIONS_URL)
        (curl-config-line "request" "POST")
        "silent"
        "show-error"
        "fail-with-body"
        (curl-config-line "header" $"Authorization: Bearer ($key)")
        (curl-config-line "form" $"file=@($audio_path)")
        (curl-config-line "form-string" $"model=($TRANSCRIPTIONS_MODEL)")
        (curl-config-line "form-string" "response_format=json")
    ]

    let curl_config = $config_lines | str join (char newline)
    let result = $curl_config | ^curl --config - | complete

    if $result.exit_code != 0 {
        err $"OpenAI transcription request failed.\nstdout:\n($result.stdout)\nstderr:\n($result.stderr)"
    }

    $result.stdout | from json
}

def audio-devices []: nothing -> table<index: int, name: string> {
    which ffmpeg | if ($in | is-empty) {
        err "The 'ffmpeg' program is not installed."
    }

    ^ffmpeg -f avfoundation -list_devices true -i "" | complete | get stderr | parse-audio-devices
}

# Among microphone devices, pick the preffered one. For me, it's a simple matter of picking the studio display mic,
# else the Macbook mic, else error out.
def choose-mic [] : {
    let mics = $in
    if ($mics | is-empty) {
        err "No mics found."
    }

    let supported_mics = $mics
        | insert score { |device|
            match $device.name {
                "Studio Display Microphone" => 2
                "MacBook Pro Microphone" => 1
                default => 0
            }
        }
        | where score > 0

    if ($supported_mics | is-empty) {
        err "No supported mics found."
    }

    $supported_mics
        | sort-by --reverse score
        | first
}

# Parse audio devices from the output of 'ffmpeg ... -list_devices'
def parse-audio-devices []: string -> table<index: int, name: string> {
    let ffmpeg_output = $in

    let after_audio_header = $ffmpeg_output
        | str replace --regex --multiline '(?s)^.*AVFoundation audio devices:\n' ''

    let devices = $after_audio_header
        | lines
        | parse --regex '\]\s+\[(?<index>\d+)\]\s+(?<name>.+)$'
        | each { |device| { index: ($device.index | into int) name: $device.name } }

    if ($devices | is-empty) {
        err $"Could not parse any audio devices from ffmpeg's output.\n($ffmpeg_output)"
    }

    $devices
}
