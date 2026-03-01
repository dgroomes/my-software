# Linux-first dev box workflow over Tart.
#
# Usage:
#   do activate
#   do pull
#   do create
#   do start

const BASE_IMAGE = "ghcr.io/cirruslabs/debian:latest"
const IMAGE_NAME = "dev-box-2-image"
const DEFAULT_VM = "dev-box-2"

def wait-for-ip [name: string, timeout_sec: int = 90] {
    let max_attempts = ($timeout_sec / 2)
    mut attempts = 0

    loop {
        $attempts = $attempts + 1
        if $attempts > $max_attempts {
            error make { msg: $"Timed out waiting for VM '($name)' to get an IP address." }
        }

        let result = (do { ^tart ip $name } | complete)
        if $result.exit_code == 0 and ($result.stdout | str trim) != "" {
            return ($result.stdout | str trim)
        }

        sleep 2sec
    }
}

export def pull [] {
    print $"Cloning base image '($BASE_IMAGE)' -> '($IMAGE_NAME)'..."
    ^tart clone $BASE_IMAGE $IMAGE_NAME
}

export def create [name: string = $DEFAULT_VM] {
    print $"Creating VM '($name)' from image '($IMAGE_NAME)'..."
    ^tart clone $IMAGE_NAME $name
}

# Start a VM headlessly and map a host directory into the guest.
#
# Defaults to mapping the current working directory as "workspace".
export def start [
    name: string = $DEFAULT_VM
    --dir: string
    --read-only(-r)
] {
    let host_dir = if $dir == null { (pwd) } else { ($dir | path expand) }
    let share = if $read_only {
        $"workspace:($host_dir):ro"
    } else {
        $"workspace:($host_dir)"
    }

    let tart_args = [run $name --no-graphics --dir $share]
    let job_id = (job spawn -t $"dev-box-2-start:($name)" {
        ^tart ...$tart_args | complete
    })

    print $"Started background job ($job_id) for VM '($name)'."
    let ip = (wait-for-ip $name)
    print $"VM '($name)' is running at ($ip)"

    vm setup-ssh $name
}

export def list [] {
    ^tart list --format json | from json
}

export def stop [
    name: string = $DEFAULT_VM
    --timeout(-t): int
] {
    mut args = [stop $name]
    if $timeout != null {
        $args = ($args | append ["--timeout" ($timeout | into string)])
    }

    ^tart ...$args
}

export def suspend [name: string = $DEFAULT_VM] {
    ^tart suspend $name
}

export def delete [name: string = $DEFAULT_VM] {
    ^tart delete $name
}
