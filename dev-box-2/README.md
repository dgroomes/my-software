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
5. Inspect VMs as structured data.
   - ```nushell
     do list
     ```
6. Stop, suspend, or delete.
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
