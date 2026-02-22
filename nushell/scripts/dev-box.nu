# Day-to-day commands for managing dev box VM instances.
#
# These commands handle the "run" side of the dev box lifecycle: starting, stopping, connecting to, and listing VMs.
# For "build" operations (pulling images, creating VMs, installing tools), see dev-box/do.nu.

# Default credentials for Cirrus Labs base images.
const VM_USER = "admin"
const VM_PASSWORD = "admin"

# Default VM name.
const DEFAULT_VM = "dev-box"

# Start a dev box VM. Runs in the background (headless) by default.
export def "dev-box start" [name: string = $DEFAULT_VM, --dir: string] {
    mut args = [run $name --no-graphics]

    if $dir != null {
        $args = ($args | append $"--dir=workspace:($dir)")
    }

    print $"Starting VM '($name)'..."

    # Run tart in the background. The VM will keep running until explicitly stopped.
    let tart_args = $args
    let job_id = (job spawn -t $"dev-box-start:($name)" {
        ^tart ...$tart_args | complete
    })
    print $"Started background job ($job_id)."
    
    # Wait for the VM to get an IP address
    print "Waiting for VM to be ready..."
    mut attempts = 0
    loop {
        $attempts = $attempts + 1
        if $attempts > 30 {
            print "Timed out waiting for VM IP address."
            return
        }
        let ip = (do { tart ip $name } | complete)
        if $ip.exit_code == 0 and ($ip.stdout | str trim) != "" {
            print $"VM '($name)' is running at ($ip.stdout | str trim)"
            break
        }
        sleep 2sec
    }
}

# List running and available dev box VMs.
export def "dev-box list" [] {
    tart list
}

# Connect to a running dev box VM via SSH.
export def "dev-box connect" [name: string = $DEFAULT_VM] {
    let ip = (tart ip $name | str trim)
    print $"Connecting to ($VM_USER)@($ip)..."
    ^sshpass -p $VM_PASSWORD ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR $"($VM_USER)@($ip)"
}

# Run a command in the dev box VM over SSH and return the output.
export def "dev-box run" [cmd: string, name: string = $DEFAULT_VM] {
    let ip = (tart ip $name | str trim)
    (^sshpass -p $VM_PASSWORD
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR
        $"($VM_USER)@($ip)"
        $cmd)
}

# Stop a running dev box VM.
export def "dev-box stop" [name: string = $DEFAULT_VM] {
    print $"Stopping VM '($name)'..."
    tart stop $name
    print $"VM '($name)' stopped."
}

# Get the IP address of a running dev box VM.
export def "dev-box ip" [name: string = $DEFAULT_VM] {
    tart ip $name | str trim
}
