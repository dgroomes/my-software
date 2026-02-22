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

# Default credentials for Cirrus Labs base images.
const VM_USER = "admin"
const VM_PASSWORD = "admin"

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

# Run a command inside the dev box VM over SSH. The VM must be running.
def ssh-cmd [vm_name: string, cmd: string] {
    let ip = (tart ip $vm_name)
    (sshpass -p $VM_PASSWORD
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR
        $"($VM_USER)@($ip)"
        $cmd)
}

# Install foundational tools in the dev box VM. The VM must be running.
#
# This is designed to be run against a freshly created VM to customize it with the tools I need. The Cirrus Labs base
# image already includes Homebrew, so we can use that as our package manager.
export def install [name: string = "dev-box"] {
    print $"Installing tools in VM '($name)'..."

    # Ensure Homebrew is up to date
    print "Updating Homebrew..."
    ssh-cmd $name "brew update"

    # Install core CLI tools
    print "Installing core CLI tools..."
    ssh-cmd $name "brew install git curl jq ripgrep fd tree"

    # Install Rust toolchain
    print "Installing Rust..."
    ssh-cmd $name "curl -sSf https://sh.rustup.rs | sh -s -- -y"

    # Install Nushell via Cargo
    print "Installing Nushell (this takes a while)..."
    ssh-cmd $name "source ~/.cargo/env && cargo install nu --locked"

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


