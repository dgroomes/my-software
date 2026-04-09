# SDR: Dev Box Bootstrapper

The decision is that there will be a lean executable that runs on a bare Linux VM to bootstrap it as my own dev box.

Status: Decided
Confidence Level: 80%

## Details

- Implemented in Go
- Is designed to be copied into a bare Linux VM (starting with Ubuntu because of Cursor Cloud agents)
- Its development and build process is generally decoupled from my-software. This is a fuzzy point. I might best develop the bootstrap code in its own repo.
- It downloads Homebrew
- It installs Nushell using Homebrew
- It might need to bootstrap some additional stuff like git (via apt) or whatever is needed to get up and running with Homebrew for Linux
- It could all be a Bash script, but I'm not willing to use Bash for this
- It clones and kicks off my-software to do the bulk of the actual dev box installation process (lots of Nushell scripting)

Using a binary as the first level of a bootstrapping goes against the grain and is a little annoying. The status quo for bootstrapping seems to be an unflinching and automatic grab for some shell code. Worse yet, it is often shell code expressed as heredocs in YAML files (think "cloud init" config). I am also tempted by this... Just curl a script from GitHub, check the hash, and run it. Where's the harm in that? The harm is in how that script grows, and we call various other programs on the computer which become implicit dependencies (curl, sha256sum, jq).

Also locating the binary into the VM and also having the VM execute the binary are both non-obvious. "cloud init" and a heredoc bash/curl snippet is the common approach. Or I could pre-bake an image locally. I don't know. When you contrast it with Dockerfiles, it makes the ergonomics of Dockerfiles look pretty awesome because we have `COPY` and `ENTRYPOINT`. So good. Maybe I'll use Packer, but I kind of want to go direct to qemu.
