# Structured VM commands over Tart.
#
# This module wraps the Tart CLI to provide a stable "vm" command namespace with
# Nushell-native structured output, tab completion, and convenient defaults.
#
# Tart is a macOS-native VM manager built on Apple's Virtualization.framework.
# It manages Linux and macOS guest VMs with OCI image support. These "vm"
# commands add value over raw Tart by:
#
#   - Returning structured records instead of plain text (vm list)
#   - Providing smart tab completion filtered by VM state (e.g. only running VMs
#     for stop/exec, only stopped VMs for run)
#   - Offering connectivity commands (vm exec, vm ssh, vm setup-ssh) that
#     eliminate the painful manual SSH workflow of IP lookup, host key prompts,
#     and password entry
#
# The connectivity story has two tiers:
#
#   1. "vm exec" — Uses the Tart guest agent over virtio-socket (vsock). This is
#      a hypervisor-level channel that bypasses networking entirely. No SSH, no
#      IP, no passwords. The guest agent (a Go binary pre-installed in Cirrus
#      Labs images) listens on vsock port 8080 and fork/execs commands via gRPC.
#      Security comes from host filesystem permissions on the Unix domain socket
#      — only the user who owns the VM can connect.
#
#   2. "vm ssh" / "vm setup-ssh" — For tools that require SSH (VS Code Remote,
#      rsync, scp). Uses SSH's ProxyCommand to tunnel the SSH connection through
#      "tart exec -i <name> nc localhost 22", routing SSH over vsock instead of
#      the network. This avoids non-deterministic DHCP IPs and host key churn
#      when VMs are frequently created and destroyed. "vm setup-ssh" handles
#      both guest-side key injection and host-side ~/.ssh/config.d/ file creation
#      in one command.

# Fetches the VM list from Tart as structured JSON records. Used by command
# bodies that need reliable data and should fail loudly on errors.
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

# ── Completion helpers ──
#
# These functions power tab completion for VM name arguments. They filter by
# Source (local only — OCI registry refs are not directly runnable) and by State
# so that e.g. "vm stop" only offers running VMs and "vm run" only offers
# stopped/suspended ones.

def vm-local-records [] {
    tart-list-json | where { |vm| ($vm.Source | str downcase) == "local" }
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

# ── Flag value completions ──
#
# These provide tab completion for flag values (--source, --format, etc.)

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

# ── Commands ──

# List VMs as structured Nushell records. Defaults to JSON parsing so you get
# a table you can filter, sort, and select from. Use --quiet for just names.
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

# Run a local VM. This is a thin wrapper over "tart run" that exposes all of
# Tart's options with tab completion. For the dev-box workflow, you typically
# use the project-level "do start" instead, which calls "tart run" with
# --no-graphics and --dir for directory sharing.
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

# Gracefully stop a running VM. Tart sends ACPI shutdown to the guest OS.
# Use --timeout to limit how long to wait before force-killing.
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

# Delete one or more local VMs. Refuses to delete running VMs — stop them first.
# Accepts multiple names for batch cleanup.
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

# Suspend a running VM to disk. The VM can be resumed later with "vm run" and
# will restore its full state (memory, processes). Useful for pausing a dev-box
# overnight without losing context.
export def "vm suspend" [
    name: string@vm-running-local-names
] {
    ^tart suspend $name
}

# Execute a command in a running VM via the Tart guest agent over virtio-socket.
# No SSH, no IP lookup, no passwords.
#
# The guest agent communicates over vsock (a hypervisor-level memory-mapped
# channel). Security is enforced by Unix file permissions on the control socket
# in ~/.tart/vms/<name>/ — only your macOS user can connect.
#
# Like "docker exec", defaults to non-interactive with no PTY. Use -i to attach
# stdin and -t to allocate a pseudo-terminal.
#
# Examples:
#   vm exec dev-box-2 uname -a           # run a command
#   vm exec -i dev-box-2 cat < file.txt  # pipe stdin into guest
#   vm exec -it dev-box-2 bash           # interactive shell (prefer "vm shell")
export def "vm exec" [
    name: string@vm-running-local-names
    --interactive(-i)           # Attach host stdin to the remote command
    --tty(-t)                   # Allocate a remote pseudo-terminal (PTY)
    ...command: string
] {
    if ($command | is-empty) {
        error make { msg: "vm exec requires a command. Use 'vm shell' for an interactive shell." }
    }

    mut args = [exec]

    if $interactive {
        $args = ($args | append "-i")
    }
    if $tty {
        $args = ($args | append "-t")
    }

    $args = ($args | append $name)
    $args = ($args | append $command)

    ^tart ...$args
}

# Open an interactive shell in a running VM via the guest agent. This is the
# fastest way to get a shell — no SSH, no IP, no passwords. Equivalent to
# "vm exec -it <name> bash" but without the flags.
export def "vm shell" [
    name: string@vm-running-local-names
] {
    ^tart exec -i -t $name bash
}

# SSH into a running VM over vsock (no IP lookup, no host key churn). Tunnels
# the SSH connection through the guest agent via ProxyCommand
# ("tart exec -i <name> nc localhost 22") to reach the guest's sshd on
# localhost:22.
#
# Extra SSH flags can be passed as trailing arguments, e.g. for port forwarding:
#   vm ssh dev-box-2 -L 8080:localhost:8080
#
# Run "vm setup-ssh <name>" first to push your SSH key and write the
# ~/.ssh/config.d/ entry for VS Code Remote SSH.
export def "vm ssh" [
    name: string@vm-running-local-names
    --user(-u): string          # SSH user (default: admin)
    ...ssh_args: string
] {
    let ssh_user = if $user != null { $user } else { "admin" }

    mut args = [
        "-o" "StrictHostKeyChecking=no"
        "-o" "UserKnownHostsFile=/dev/null"
        "-o" "LogLevel=ERROR"
        "-o" $"ProxyCommand=tart exec -i ($name) nc localhost 22"
    ]
    $args = ($args | append $ssh_args)
    ^ssh ...$args $"($ssh_user)@($name)"
}

# Forward a host port to a port inside the VM. Uses an SSH tunnel over vsock,
# so no IP lookup is needed. After running this, localhost:<host_port> on your
# Mac reaches <vm_port> inside the guest.
#
# Examples:
#   vm forward dev-box-2 8080         # host 8080 → guest 8080
#   vm forward dev-box-2 8080 3000    # host 8080 → guest 3000
export def "vm forward" [
    name: string@vm-running-local-names
    host_port: int
    vm_port?: int
    --user(-u): string
] {
    let ssh_user = if $user != null { $user } else { "admin" }
    let guest_port = if $vm_port != null { $vm_port } else { $host_port }

    let forward = $"($host_port):localhost:($guest_port)"
    print $"Forwarding localhost:($host_port) → ($name):($guest_port)"

    let args = [
        -N -L $forward
        -o StrictHostKeyChecking=no
        -o UserKnownHostsFile=/dev/null
        -o LogLevel=ERROR
        -o $"ProxyCommand=tart exec -i ($name) nc localhost 22"
        $"($ssh_user)@($name)"
    ]
    ^ssh ...$args
}

# One-time SSH setup for a running VM. Does two things:
#
#   1. Guest side: pushes your SSH public key into the VM's authorized_keys so
#      future connections are passwordless.
#
#   2. Host side: writes a file to ~/.ssh/config.d/vm-<name> with the
#      ProxyCommand and host key suppression settings. This makes "ssh <name>"
#      and VS Code Remote SSH work with zero prompts.
#
# Uses SSH's Include directive (added to ~/.ssh/config if not present) so each
# VM gets its own file — no fragile text manipulation of the main config.
# Idempotent: overwrites the config.d file and appends the key (duplicates in
# authorized_keys are harmless).
export def "vm setup-ssh" [
    name: string@vm-running-local-names
    --user(-u): string          # Guest user (default: admin)
    --key: string               # Path to public key (default: ~/.ssh/id_ed25519.pub)
] {
    let ssh_user = if $user != null { $user } else { "admin" }
    let key_path = if $key != null { $key } else { "~/.ssh/id_ed25519.pub" | path expand }

    if not ($key_path | path exists) {
        error make { msg: $"Public key not found: ($key_path)" }
    }

    let pubkey = (open $key_path | str trim)

    let setup_script = $"mkdir -p /home/($ssh_user)/.ssh && chmod 700 /home/($ssh_user)/.ssh && echo '($pubkey)' >> /home/($ssh_user)/.ssh/authorized_keys && chmod 600 /home/($ssh_user)/.ssh/authorized_keys"

    ^tart exec -i $name sh -c $setup_script
    print $"SSH public key installed for '($ssh_user)' on VM '($name)'."

    let config_dir = "~/.ssh/config.d" | path expand
    mkdir $config_dir

    let ssh_config_path = "~/.ssh/config" | path expand
    let include_line = "Include config.d/*"
    if ($ssh_config_path | path exists) {
        let existing = (open $ssh_config_path)
        if not ($existing | str contains $include_line) {
            [$include_line $existing] | save -f $ssh_config_path
        }
    } else {
        [$include_line] | save $ssh_config_path
    }

    let host_file = $"($config_dir)/vm-($name)"
    [$"Host ($name)"
        $"    User ($ssh_user)"
        $"    ProxyCommand tart exec -i ($name) nc localhost 22"
        "    StrictHostKeyChecking no"
        "    UserKnownHostsFile /dev/null"
    ] | save -f $host_file

    print $"SSH config written to ($host_file). You can now use: ssh ($name)"
}
