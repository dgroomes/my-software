# dev-box-2

In progress.

We're building up an understanding of how to run a simple Tart CLI-based VM using Apple's Virtualization framework to run Linux with a mapped working directory for long-horizon, unsupervised, offline-friendly agentic programming.


## Direction

- Linux guest VMs only.
- We are not pursuing macOS guests in this track.
- Base image: `ghcr.io/cirruslabs/debian:latest`.


## Current Workflow

From `dev-box-2/`:

1. Activate the project script.
   - ```nushell
     do activate
     ```
2. Pull the Debian base image into a local image name.
   - ```nushell
     do pull
     ```
3. Create a runnable VM clone from the local image.
   - ```nushell
     do create
     ```
4. Start headless and map the current directory into the guest (`workspace:<pwd>`).
   - ```nushell
     do start
     ```
5. Get a shell in the VM (no SSH, no passwords, no IP lookup).
   - ```nushell
     vm shell dev-box-2
     ```
6. Or SSH in (uses vsock proxy — no IP lookup, no host key prompts).
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

`do start --dir <path>` maps a different host directory:

```nushell
do start --dir ~/some/path
```


## VM Command Layer

`nushell/scripts/vm.nu` is the structured wrapper over Tart and is wired into Nushell config/install flows.

Primary commands:

- `vm list`
- `vm run`
- `vm stop`
- `vm delete`
- `vm suspend`
- `vm exec` — run a command via guest agent (like docker exec)
- `vm shell` — interactive shell via guest agent (no SSH)
- `vm ssh` — SSH via vsock proxy (no IP lookup)
- `vm forward` — port forwarding (e.g. `vm forward dev-box-2 8080`)
- `vm setup-ssh` — push SSH key into VM for passwordless access


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

- [ ] IN PROGRESS Flesh out `vm.nu` into a stable "daily-driver" command layer. I like the structured output and completions. I'm not sure I want the ssh setup stuff. I think we just will ssh via tart exect.
- [ ] First cut at dev-box. We will rename it from dev-box-2 to dev-box. Incorporate some of the "vision" language from the 'dev-box' branch (we are on the dev-box-2 branch), and have a starting point for the next wish list items.
- [ ] Flesh out `dev-box` environment bootstrap. Add Nushell, core CLI tools, git). This should be like my dev docker container.
   - This may be challenging. There is no Dockerfile here. What does an install even look like? Some good ole' scripting here.
- [ ] Explore a proxy-server (external process) for sandboxing API keys and similar secrets. The goal is to keep sensitive credentials out of the VM while still allowing agent workflows to call external APIs through a controlled, auditable host-side boundary.
- [ ] Figure out what Tart `softnet` actually is, how it behaves in practice, and whether it is needed in `vm.nu` for this project's default path.
- [ ] Revisit the `vm forward` port-forwarding functionality and decide if we should keep it, simplify it, or replace it with a clearer recommended workflow.
