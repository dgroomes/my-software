# dev-box

WORK IN PROGRESS

My personal VM-based Linux "dev box" for doing development work on a Mac.   


## Overview

I want a sandboxed, repeatable, and richly capable development environment where agentic coding tools can run freely
over long task horizons without risk to my host system and data. The idea of a "development box" (dev box) is not new.
[Development Containers][dev-containers] is a notable branded effort that standardizes this concept using an ecosystem
around containers, and there are many so-called "cloud dev environments" (CDEs) like [Coder][coder] and
[GitHub Codespaces][github-codespaces]. I've explored some of these concepts and taken my own notes in:

- <https://github.com/dgroomes/dev-containers-playground>
- <https://github.com/dgroomes/docker-playground/tree/main/docker-in-docker>

Overall, I've found the layering of Linux VMs, Docker daemons, and container runtimes on macOS to be an accumulation of incidental complexity. I want to eject from the common wisdom of using a Docker container as a "dev box" and instead
use a VM directly.

macOS is my development platform. I invest in understanding it, I configure it the way I like, and I don't want to abandon that by delegating my dev environment to Docker's Linux VM machinery and whatever Linux distro I use for the dev box. Apple's [Virtualization framework][virtualization-framework] lets us run macOS VMs natively on Apple Silicon with near-native performance. [Tart][tart] is a CLI tool built on top of this framework. With Tart, I can clone a base macOS image, customize it with my tools, and spin up fresh VM instances as needed.

So my thinking is that my "dev box" can itself be macOS. Well, that *was* my thinking until I realized that the [Virtualization
framework doesn't support nested virtualization for macOS guest VMs](https://github.com/cirruslabs/tart/discussions/701).
That's disappointing, but not the end of the world. I concede that my "dev box" will have to be Linux because I do in fact
need nested virtualization because many projects I work on revolve around running local Docker containers.

So, the "dev box" right now is just shell scripting that helps me run Linux VMs with Tart. So far, I've decided to define
a set of `vm` commands in `../nushell/scripts/vm.nu` and have carved out the `dev-box/` subproject to be an extra layer for doing dev-box specific things over the `vm` layer.


## Relation to Agentic Development

The "dev box" subproject is not trying to define a control plane for agentic development. It is solving a simpler problem: my own dev boxes. The idea is that an agentic control plane, running on the macOS host, makes use of these dev box VMs. The agent process stays on the host (where it has access to credentials, API keys, etc.) and sends commands into the VM over SSH. This is consistent with my [strategy on consolidating control][strategy]: the host remains the center of gravity.


## Instructions

Follow these instructions to create and use a "dev box".

1. Overlay the `vm` and project scripts
   - ```nushell
     overlay use --prefix ../nushell/scripts/vm.nu
     ```
   - ```nushell
     overlay use --prefix do.nu
     ```
2. Pull the base image into a local image name
   - ```nushell
     do pull
     ```
3. Create a runnable VM clone from the local image
   - ```nushell
     do create
     ```
4. Start headless and map the current directory into the guest
   - ```nushell
     do start
     ```
5. Get a shell in the VM (no SSH, no passwords, no IP lookup).
   - ```nushell
     vm shell dev-box-2
     ```
6. Or SSH in
   - One-time setup to push your SSH key:
     ```nushell
     vm setup-ssh dev-box-2
     ```
   - Then connect:
     ```nushell
     vm ssh dev-box-2
     ```
7. Inspect VMs as structured data.
   - ```nushell
     do list
     ```
8. Stop, suspend, or delete.
   - ```nushell
     do stop
     do suspend
     do delete
     ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

- [ ] IN PROGRESS Flesh out `vm.nu` into a stable "daily-driver" command layer. I like the structured output and completions. I'm not sure I want the ssh setup stuff. I think we just will ssh via tart exec.
   - DONE Reduce `vm.nu`. I tried "letting it go" but the chaos accumulates too fast. We have something working (the first important part) but now we need to capture it to `main` and NOT capture toxic waste (the 2nd important part?)
   - Make the conntectivity story clear. I really like the `vm shell` command as a compressed, direct, and interpretable (I mean if you can fit in your mental model that there is a Tart agent) way to get from your host commandline to a commandline in the dev box. What I want to do is compare/contrast it with an SSH based flow, which accomplishes the same thing but by way of SSH machinery both on the client and server side. We need to treat SSH as a first class citizen because of its ubiquity (I plan to connect via VS Code's SSH remote development facilities, and maybe even JetBrains' as well). Wait, I'm continually confused about how terminal emulators (or the PTY?) work... if I `tart exec -it dev-box-2 bash` into the VM... how is my terminal width being communicated? Is SSH in the mix actually? Interesting, when connecting with SSH there are more env vars, like XDG_ ones and more bizarelly the PATH is quite different. It seems like the Tart agent route is a non-login shell, which keeps me some pause.
- [ ] First cut at dev-box. We will rename it from dev-box-2 to dev-box. Incorporate some of the "vision" language from the 'dev-box' branch (we are on the dev-box-2 branch), and have a starting point for the next wish list items.
- [ ] Flesh out `dev-box` environment bootstrap. Add Nushell, core CLI tools, git). This should be like my dev docker container.
   - This may be challenging. There is no Dockerfile here. What does an install even look like? Some good ole' scripting here.
- [ ] Explore a proxy-server (external process) for sandboxing API keys and similar secrets. The goal is to keep sensitive credentials out of the VM while still allowing agent workflows to call external APIs through a controlled, auditable host-side boundary.
- [ ] Figure out what Tart `softnet` actually is, how it behaves in practice, and whether it is needed in `vm.nu` for this project's default path.
- [ ] Revisit the `vm forward` port-forwarding functionality and decide if we should keep it, simplify it, or replace it with a clearer recommended workflow.
- [ ] `known_hosts` is not being written to in the ssh flow. Not sure why. This is causing the "permanently added" line to print everytime I connect which is noise.


## Reference

- [Tart][tart]
- [Apple Virtualization framework][virtualization-framework]
- [Development Containers specification][dev-containers]

[tart]: https://github.com/cirruslabs/tart
[virtualization-framework]: https://developer.apple.com/documentation/virtualization
[dev-containers]: https://containers.dev/
[coder]: https://coder.com
[github-codespaces]: https://github.com/features/codespaces
