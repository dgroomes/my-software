# dev-box

A customized macOS development environment box, running as a virtual machine on the host Mac.


## Overview

I want a sandboxed, disposable development environment where agentic coding tools can run freely over long task horizons
without risk to my host system. The idea of a "development box" (dev box) is not new. [Development Containers][dev-containers]
is a notable branded effort that standardizes this concept using Docker containers, and tools like [DevPod][dev-pod]
build on that foundation. I've explored these options in [my dev-containers-playground][dev-containers-playground] and
[Docker-in-Docker experiments][docker-in-docker], but I've found the layering of Linux VMs, Docker daemons, and
container runtimes on macOS to be an accumulation of incidental complexity.

macOS is my development platform. I invest in understanding it, I configure it the way I like, and I don't want to
abandon that by delegating my dev environment to Docker's Linux VM machinery. Apple's [Virtualization framework][virtualization-framework]
lets us run macOS VMs natively on Apple Silicon with near-native performance. [Tart][tart] is a CLI tool built on top of
this framework. With Tart, I can clone a base macOS image, customize it with my tools, and spin up fresh VM instances as
needed.

This subproject is *not* trying to define a control plane for agentic development. It is solving a simpler problem: my
own dev boxes. The idea is that an agentic control plane, running on the macOS host, makes use of these dev box VMs. The
agent process stays on the host (where it has access to credentials, API keys, etc.) and sends commands into the VM over
SSH. This is consistent with my [strategy on consolidating control][strategy] — the host remains the center of gravity.

### Networking

Tart VMs use macOS's built-in [vmnet framework][vmnet] for networking. By default, VMs get a NAT network with DHCP-assigned
IP addresses on a `192.168.64.0/24` subnet. The VM can reach the internet and can reach the host (via the gateway IP).
The host can reach the VM via the IP reported by `tart ip`. SSH access is the primary interface for interacting with
the VM.

### Directory Sharing

Tart supports mounting host directories into the VM using Apple's VirtioFS. Mounted directories appear at
`/Volumes/My Shared Files/<name>` inside macOS guests. Use the `--dir=<name>:<host-path>` flag with `tart run` to share
directories. Read-only mounts are also supported with a `:ro` suffix. This is how we get project files into the VM
without needing to clone repositories inside it.


## Instructions

Follow these instructions to build a dev box image and create a VM instance from it.

1. Activate the `do.nu` script
   - ```nushell
     do activate
     ```
2. Pull the base macOS image
   - ```nushell
     do pull
     ```
3. Create a dev box image from the base
   - ```nushell
     do create
     ```
4. Install tools in the dev box image
   - ```nushell
     do install
     ```
5. Start a dev box VM instance
   - The `dev-box.nu` script in `nushell/scripts/` provides day-to-day commands. Source it via:
   - ```nushell
     do source-dev-box
     ```
   - Then start a VM:
   - ```nushell
     dev-box start
     ```
6. Connect to the dev box via SSH
   - ```nushell
     dev-box connect
     ```
7. Stop the VM when done
   - ```nushell
     dev-box stop
     ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

- [ ] Flesh out installation commands for more tools: Homebrew, Git, Nushell, Starship, Node.js, Go, Rust/Cargo, etc.
      This list will grow long over time. See `docker/my-dev/` for a reference of what I install in my Docker-based dev
      image.
- [ ] Develop a convention for snapshotting a fully-configured VM image so that new instances start fast without
      repeating the install steps.
- [ ] Explore SSH key-based authentication instead of password-based.
- [ ] Figure out a good rsync or file-sync story for getting project files into the VM efficiently, as an alternative
      or complement to VirtioFS directory sharing.
- [ ] Consider disk resizing for the base image (default may be too small for heavy development).
- [ ] Define an agentic runbook: instructions for an agent to follow when setting up and working inside a dev box.
- [ ] Explore Tart's `--net-softnet` for stricter network isolation when needed.
- [ ] Layer in my Nushell scripts and configuration into the VM image.
- [ ] Consider using `tart export`/`tart import` for sharing images across machines.


## Reference

- [Tart][tart]
- [Apple Virtualization framework][virtualization-framework]
- [Development Containers specification][dev-containers]
- [DevPod][dev-pod]

[tart]: https://github.com/cirruslabs/tart
[virtualization-framework]: https://developer.apple.com/documentation/virtualization
[vmnet]: https://developer.apple.com/documentation/vmnet
[dev-containers]: https://containers.dev/
[dev-pod]: https://github.com/loft-sh/devpod
[dev-containers-playground]: .my/repos/dev-containers-playground
[docker-in-docker]: .my/repos/docker-playground/docker-in-docker
[strategy]: ../strategy/README.md
