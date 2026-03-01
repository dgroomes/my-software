# Structured VM commands over Tart.
#
# The goal is to keep "vm" as the stable, user-facing command namespace while still exposing Tart's useful options.

# Strict helper for command bodies.
def tart-list-json [] {
    let result = (do { ^tart list --format json } | complete)
    if $result.exit_code != 0 {
        error make { msg: $"Failed to execute 'tart list --format json': ($result.stderr | str trim)" }
    }

    try {
        $result.stdout | from json
    } catch {
        error make { msg: "Failed to parse JSON from 'tart list --format json'." }
    }
}

# Best-effort helper for completion functions.
def tart-list-json-safe [] {
    try {
        tart-list-json
    } catch {
        []
    }
}

def vm-local-records [] {
    tart-list-json-safe | where { |vm| ($vm.Source | str downcase) == "local" }
}

def vm-local-names [] {
    vm-local-records | each { |vm| $vm.Name }
}

def vm-running-local-names [] {
    vm-local-records | where { |vm| $vm.State == "running" } | each { |vm| $vm.Name }
}

def vm-startable-local-names [] {
    vm-local-records | where { |vm| $vm.State != "running" } | each { |vm| $vm.Name }
}

def vm-list-sources [] {
    [
        { value: "local", description: "Only local VMs" }
        { value: "oci", description: "Only OCI-backed VMs" }
    ]
}

def vm-list-formats [] {
    [
        { value: "json", description: "Structured output (recommended)" }
        { value: "text", description: "Raw Tart text output" }
    ]
}

def vm-rosetta-tags [] {
    ["rosetta"]
}

def vm-net-bridged-values [] {
    [
        { value: "list", description: "List available bridged interfaces" }
    ]
}

def vm-root-disk-opts [] {
    [
        "ro"
        "sync=none"
        "sync=fsync"
        "sync=full"
        "caching=automatic"
        "caching=cached"
        "caching=uncached"
    ]
}

# List VMs. Defaults to JSON + structured output.
export def "vm list" [
    --source: string@vm-list-sources
    --format: string@vm-list-formats
    --quiet(-q)
] {
    mut args = [list]
    if $source != null {
        $args = ($args | append ["--source" $source])
    }
    if $quiet {
        $args = ($args | append "--quiet")
    }

    let effective_format = if $format == null and not $quiet { "json" } else { $format }
    if $effective_format != null {
        $args = ($args | append ["--format" $effective_format])
    }

    let tart_args = $args
    let result = (do { ^tart ...$tart_args } | complete)
    if $result.exit_code != 0 {
        error make { msg: ($result.stderr | str trim) }
    }

    if $quiet {
        return ($result.stdout | lines | where { |line| ($line | str trim) != "" })
    }

    if $effective_format == "json" {
        return ($result.stdout | from json)
    }

    $result.stdout | str trim
}

# Run a local VM.
export def "vm run" [
    name: string@vm-startable-local-names
    --no-graphics
    --serial
    --serial-path: string
    --no-audio
    --no-clipboard
    --recovery
    --vnc
    --vnc-experimental
    --disk: string
    --rosetta: string@vm-rosetta-tags
    --dir: string
    --nested
    --net-bridged: string@vm-net-bridged-values
    --net-softnet
    --net-softnet-allow: string
    --net-softnet-block: string
    --net-softnet-expose: string
    --net-host
    --root-disk-opts: string@vm-root-disk-opts
    --suspendable
    --capture-system-keys
    --no-trackpad
    --no-pointer
    --no-keyboard
] {
    if $vnc and $vnc_experimental {
        error make { msg: "--vnc and --vnc-experimental are mutually exclusive." }
    }

    mut use_softnet = $net_softnet
    if $net_softnet_allow != null or $net_softnet_block != null or $net_softnet_expose != null {
        $use_softnet = true
    }

    let network_mode_count = ([
        ($net_bridged != null)
        $use_softnet
        $net_host
    ] | where { |it| $it } | length)
    if $network_mode_count > 1 {
        error make { msg: "--net-bridged, --net-softnet and --net-host are mutually exclusive." }
    }

    mut args = [run $name]
    if $no_graphics {
        $args = ($args | append "--no-graphics")
    }
    if $serial {
        $args = ($args | append "--serial")
    }
    if $serial_path != null {
        $args = ($args | append ["--serial-path" $serial_path])
    }
    if $no_audio {
        $args = ($args | append "--no-audio")
    }
    if $no_clipboard {
        $args = ($args | append "--no-clipboard")
    }
    if $recovery {
        $args = ($args | append "--recovery")
    }
    if $vnc {
        $args = ($args | append "--vnc")
    }
    if $vnc_experimental {
        $args = ($args | append "--vnc-experimental")
    }
    if $disk != null {
        $args = ($args | append ["--disk" $disk])
    }
    if $rosetta != null {
        $args = ($args | append ["--rosetta" $rosetta])
    }
    if $dir != null {
        $args = ($args | append ["--dir" $dir])
    }
    if $nested {
        $args = ($args | append "--nested")
    }
    if $net_bridged != null {
        $args = ($args | append ["--net-bridged" $net_bridged])
    }
    if $use_softnet {
        $args = ($args | append "--net-softnet")
    }
    if $net_softnet_allow != null {
        $args = ($args | append ["--net-softnet-allow" $net_softnet_allow])
    }
    if $net_softnet_block != null {
        $args = ($args | append ["--net-softnet-block" $net_softnet_block])
    }
    if $net_softnet_expose != null {
        $args = ($args | append ["--net-softnet-expose" $net_softnet_expose])
    }
    if $net_host {
        $args = ($args | append "--net-host")
    }
    if $root_disk_opts != null {
        $args = ($args | append ["--root-disk-opts" $root_disk_opts])
    }
    if $suspendable {
        $args = ($args | append "--suspendable")
    }
    if $capture_system_keys {
        $args = ($args | append "--capture-system-keys")
    }
    if $no_trackpad {
        $args = ($args | append "--no-trackpad")
    }
    if $no_pointer {
        $args = ($args | append "--no-pointer")
    }
    if $no_keyboard {
        $args = ($args | append "--no-keyboard")
    }

    ^tart ...$args
}

export def "vm stop" [
    name: string@vm-running-local-names
    --timeout(-t): int
] {
    mut args = [stop $name]
    if $timeout != null {
        $args = ($args | append ["--timeout" ($timeout | into string)])
    }
    ^tart ...$args
}

export def "vm delete" [
    ...names: string@vm-startable-local-names
] {
    if ($names | is-empty) {
        error make { msg: "At least one VM name is required." }
    }

    let running = vm-running-local-names
    let still_running = ($names | where { |name| $name in $running })
    if not ($still_running | is-empty) {
        error make { msg: $"Refusing to delete running VMs: ($still_running | str join ', ')." }
    }

    let known = vm-local-names
    let unknown = ($names | where { |name| not ($name in $known) })
    if not ($unknown | is-empty) {
        error make { msg: $"Unknown local VM names: ($unknown | str join ', ')." }
    }

    ^tart delete ...$names
}

export def "vm suspend" [
    name: string@vm-running-local-names
] {
    ^tart suspend $name
}

export def "vm ip" [
    name: string@vm-running-local-names
    --wait(-w): int
    --resolver: string
] {
    mut args = [ip $name]
    if $wait != null {
        $args = ($args | append ["--wait" ($wait | into string)])
    }
    if $resolver != null {
        $args = ($args | append ["--resolver" $resolver])
    }
    ^tart ...$args | str trim
}

# Execute a command in a running VM via the guest agent (no SSH needed).
#
# With no command, opens an interactive shell.
export def "vm exec" [
    name: string@vm-running-local-names
    --no-interactive(-I)        # Don't attach stdin (default is interactive)
    --no-tty(-T)                # Don't allocate a PTY (default is TTY when no command given)
    ...command: string
] {
    mut args = [exec]

    let has_command = not ($command | is-empty)

    if not $no_interactive {
        $args = ($args | append "-i")
    }
    if not $no_tty {
        $args = ($args | append "-t")
    }

    $args = ($args | append $name)

    if $has_command {
        $args = ($args | append $command)
    } else {
        $args = ($args | append "bash")
    }

    ^tart ...$args
}

# SSH into a running VM. Uses the guest agent as a transport (ProxyCommand over vsock).
#
# Falls back to direct IP-based SSH if --direct is given.
export def "vm ssh" [
    name: string@vm-running-local-names
    --user(-u): string          # SSH user (default: admin)
    --direct(-d)                # Use IP-based SSH instead of vsock proxy
    ...ssh_args: string
] {
    let ssh_user = if $user != null { $user } else { "admin" }

    mut args = [
        "-o" "StrictHostKeyChecking=no"
        "-o" "UserKnownHostsFile=/dev/null"
        "-o" "LogLevel=ERROR"
    ]

    if $direct {
        let ip = (^tart ip --wait 30 $name | str trim)
        $args = ($args | append $ssh_args)
        ^ssh ...$args $"($ssh_user)@($ip)"
    } else {
        $args = ($args | append ["-o" $"ProxyCommand=tart exec -i ($name) nc localhost 22"])
        $args = ($args | append $ssh_args)
        ^ssh ...$args $"($ssh_user)@($name)"
    }
}

# Push your SSH public key into a running VM so future SSH is passwordless.
export def "vm setup-ssh" [
    name: string@vm-running-local-names
    --user(-u): string          # Guest user (default: admin)
    --key: string               # Path to public key (default: ~/.ssh/id_ed25519.pub)
] {
    let ssh_user = if $user != null { $user } else { "admin" }
    let key_path = if $key != null { $key } else { $"($env.HOME)/.ssh/id_ed25519.pub" }

    if not ($key_path | path exists) {
        error make { msg: $"Public key not found: ($key_path)" }
    }

    let pubkey = (open $key_path | str trim)

    let setup_script = $"mkdir -p /home/($ssh_user)/.ssh && chmod 700 /home/($ssh_user)/.ssh && echo '($pubkey)' >> /home/($ssh_user)/.ssh/authorized_keys && chmod 600 /home/($ssh_user)/.ssh/authorized_keys"

    ^tart exec -i $name sh -c $setup_script

    print $"SSH public key installed for '($ssh_user)' on VM '($name)'."
}
