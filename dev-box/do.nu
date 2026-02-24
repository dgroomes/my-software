# Build and configure a macOS dev box VM using Tart.
#
# This script handles the "build" side of the dev box lifecycle: pulling base images, creating VMs, and installing tools
# inside them. For day-to-day "start/stop/connect" operations, see nushell/scripts/dev-box.nu.

const DIR = path self | path dirname

# The base macOS image to clone from. Cirrus Labs publishes pre-built images on GHCR.
# The "base" images include Homebrew and basic CLI tools. The "vanilla" images are bare macOS.
const BASE_IMAGE = "ghcr.io/cirruslabs/macos-tahoe-base:latest"

# The name of our dev box VM image. This is the customized image we build on top of the base.
const IMAGE_NAME = "my-dev-box"

# Default user for Cirrus Labs base images.
const VM_USER = "admin"

# Pull (clone) the base macOS image from the remote OCI registry.
export def pull [] {
    print $"Pulling base image: ($BASE_IMAGE)"
    tart clone $BASE_IMAGE $IMAGE_NAME
    print "Base image pulled successfully."
}

# Create a dev box VM instance from the image. This is a clone operation — the original image is preserved.
export def create [name: string = "dev-box"] {
    print $"Creating VM '($name)' from image '($IMAGE_NAME)'..."
    tart clone $IMAGE_NAME $name
    print $"VM '($name)' created."
}

# Run a shell command inside the dev box VM using Tart Guest Agent.
#
# This avoids interactive SSH/password auth during provisioning.
def vm-cmd [vm_name: string, cmd: string] {
    tart exec $vm_name /bin/zsh -lc $cmd
}

def wait-for-vm [name: string, timeout_sec: int = 90] {
    let max_attempts = ($timeout_sec / 2)
    mut attempts = 0
    loop {
        $attempts = $attempts + 1
        if $attempts > $max_attempts {
            error make {msg: $"Timed out waiting for VM '($name)' to be ready."}
        }

        let ip = (do { tart ip $name } | complete)
        if $ip.exit_code == 0 and ($ip.stdout | str trim) != "" {
            return ($ip.stdout | str trim)
        }

        sleep 2sec
    }
}

# Install foundational tools in the dev box VM. The VM must be running.
#
# This is designed to be run against a freshly created VM to customize it with the tools I need. The Cirrus Labs base
# image already includes Homebrew, so we can use that as our package manager.
export def install [name: string = "dev-box"] {
    print $"Installing tools in VM '($name)'..."

    # Ensure Homebrew is up to date
    print "Updating Homebrew..."
    vm-cmd $name "brew update"

    # Install core CLI tools
    print "Installing core CLI tools..."
    vm-cmd $name "brew install git curl jq ripgrep fd tree"

    # Install Rust toolchain
    print "Installing Rust..."
    vm-cmd $name "curl -sSf https://sh.rustup.rs | sh -s -- -y"

    # Install Nushell via Cargo
    print "Installing Nushell (this takes a while)..."
    vm-cmd $name "source ~/.cargo/env && cargo install nu --locked"

    print $"Installation complete for VM '($name)'."
}

# List all Tart VMs (both images and running instances).
export def list [] {
    tart list
}

# Delete a dev box VM.
export def delete [name: string = "dev-box"] {
    print $"Deleting VM '($name)'..."
    tart delete $name
    print $"VM '($name)' deleted."
}

# Create a VM instance, start it headless, and install a host SSH public key into the guest in one command.
#
# This gives you frictionless, key-based SSH without interactive password login.
# NOTE: I'm not sure about this.
export def bootstrap [name: string = "dev-box", pubkey_file: string = "~/.ssh/id_ed25519.pub"] {
    let pubkey_path = ($pubkey_file | path expand)
    if not ($pubkey_path | path exists) {
        error make {msg: $"Public key file not found: ($pubkey_path)"}
    }

    print $"Creating VM '($name)' from image '($IMAGE_NAME)'..."
    let create_result = (do { tart clone $IMAGE_NAME $name } | complete)
    if $create_result.exit_code != 0 {
        let stderr = ($create_result.stderr | default "")
        if ($stderr | str contains "already exists") {
            print $"VM '($name)' already exists. Continuing..."
        } else {
            error make {msg: $"Failed to create VM '($name)': ($stderr)"}
        }
    }

    print $"Starting VM '($name)' in background..."
    let job_id = (job spawn -t $"dev-box-bootstrap:($name)" {
        tart run $name --no-graphics | complete
    })
    print $"Started background job ($job_id)."

    print "Waiting for VM to become reachable..."
    let ip = (wait-for-vm $name)
    print $"VM '($name)' is running at ($ip)"

    let pubkey = (open --raw $pubkey_path | str trim)
    let escaped_pubkey = ($pubkey | str replace --all "'" "'\"'\"'")
    let inject_cmd = $"mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && grep -qxF '($escaped_pubkey)' ~/.ssh/authorized_keys || printf '%s\\n' '($escaped_pubkey)' >> ~/.ssh/authorized_keys"

    print $"Injecting public key from '($pubkey_path)' into VM '($name)'..."
    vm-cmd $name $inject_cmd

    print $"Done. You can now connect with: ssh ($VM_USER)@($ip)"
}


