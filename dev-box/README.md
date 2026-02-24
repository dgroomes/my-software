# dev-box

My personal macOS virtual machine "dev box".


## Overview

I want a sandboxed, repeatable, and richly capable development environment where agentic coding tools can run freely over long task horizons without risk to my host system. The idea of a "development box" (dev box) is not new. [Development Containers][dev-containers] is a notable branded effort that standardizes this concept using Docker containers, and there are many so-called "cloud dev environments" (CDEs) like [Coder][coder] and [GitHub Codespaces][github-codespaces]. I've explored some of these concepts and taken my own notes in:

- <https://github.com/dgroomes/dev-containers-playground>
- <https://github.com/dgroomes/docker-playground/tree/main/docker-in-docker>

Overall, I've found the layering of Linux VMs, Docker daemons, and container runtimes on macOS to be an accumulation of incidental complexity. I want to eject from the common wisdom of using a Docker container as a "dev box" and instead use a macOS VM. 

macOS is my development platform. I invest in understanding it, I configure it the way I like, and I don't want to abandon that by delegating my dev environment to Docker's Linux VM machinery and whatever Linux distro I use for the dev box. Apple's [Virtualization framework][virtualization-framework] lets us run macOS VMs natively on Apple Silicon with near-native performance. [Tart][tart] is a CLI tool built on top of this framework. With Tart, I can clone a base macOS image, customize it with my tools, and spin up fresh VM instances as needed.

This subproject is *not* trying to define a control plane for agentic development. It is solving a simpler problem: my own dev boxes. The idea is that an agentic control plane, running on the macOS host, makes use of these dev box VMs. The agent process stays on the host (where it has access to credentials, API keys, etc.) and sends commands into the VM over SSH. This is consistent with my [strategy on consolidating control][strategy]: the host remains the center of gravity.


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
3. One-shot bootstrap (create + start + inject SSH public key)
   - ```nushell
     do bootstrap
     ```
   - This avoids interactive password login by injecting `~/.ssh/id_ed25519.pub` into the guest via `tart exec`.
4. Create a dev box image from the base
   - ```nushell
     do create
     ```
5. Install tools in the dev box image
   - ```nushell
     do install
     ```
6. Start a dev box VM instance
   - The `dev-box.nu` script in `nushell/scripts/` provides day-to-day commands. Overlay it via:
   - ```nushell
     overlay use ../nushell/scripts/dev-box.nu
     ```
   - Then start a VM:
   - ```nushell
     dev-box start
     ```
7. Connect to the dev box via SSH
   - ```nushell
     dev-box connect
     ```
8. Stop the VM when done
   - ```nushell
     dev-box stop
     ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

- [ ] Flesh out installation commands for more tools: Homebrew, Git, Nushell, Starship, Node.js, Go, Rust/Cargo, etc. This list will grow long over time. See `docker/my-dev/` for a reference of what I install in my Docker-based dev image.
- [ ] Explore Tart's `--net-softnet` for stricter network isolation when needed.
- [ ] Layer in my Nushell scripts and configuration into the VM image.
- [ ] Smooth out auth. The manual steps need to be as compressed as possible
- [ ] Nested virtualization. I indeed probably want Docker (colima?) inside the VM which means we'll need to run the nested Linux VM. This is clearly "hat on hat" and should only be pursued if I prove out the sane use-case first.  


## Reference

- [Tart][tart]
- [Apple Virtualization framework][virtualization-framework]
- [Development Containers specification][dev-containers]

[tart]: https://github.com/cirruslabs/tart
[virtualization-framework]: https://developer.apple.com/documentation/virtualization
[dev-containers]: https://containers.dev/
[dev-containers-playground]: https://github.com/dgroomes/dev-containers-playground
[coder]: https://coder.com
[github-codespaces]: https://github.com/features/codespaces
