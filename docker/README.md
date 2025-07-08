# docker

Docker configurations and conventions that support my personal workflows.


## Overview

I generally like to use the native macOS host environment for my development work, and to enjoy the speed, interpretability, and comfort of a native setup. However, virtualization is sometimes a must, and the right tool.

I'm finding this especially true for agentic tools like Claude Code. I also sometimes need it for tools that just aren't as well supported on macOS.

This `docker` directory is for me to build up my own conventions, Docker images, and ideas around how Docker fits into my dev workflow.


## `my-dev` Docker Image

The `my-dev` Docker image is designed as a base image for my development work that happens in containers.


## Miscellaneous Notes

* I do *not* want to just use Docker for the sake of using it.
* I like the ethos of package managers. I want to get leverage out of them, and sprinkle in custom build scripts to fill in the gaps between what they offer and the snowflakes of what I need and the snowflakes of dependencies I use that don't always exist in package managers
* Right now, I am not intending to build Docker images for a "runtime" workload. So, not sure I'll use build stages much. My workloads are all just more dev environments to build even more software
* I prefer the Docker *exec* form of `RUN`. I really don't like the *shell* form of `RUN`.
* I don't like the ergonomics of `Dockerfile` files. I don't like how the ecosystem has chosen to do heavy inheritance-based relationships of "using the Node Docker image for Node apps", or "using the Python Docker image for Python apps". What if you need both?
* I'd like to inherit from a base Linux distribution image, then layer in the tools I need via COPY'ed in scripts


## Instructions

Follow these instructions to work with Docker configurations in this directory.

1. Activate the `do.nu` script 
   * ```nushell
     do activate
     ```
2. Build the `my-dev` image
   * ```nushell
     do build-my-dev
     ```
3. Say "hello world" from the container
   * ```nushell
     docker run --rm my-dev:local node -e "console.log('Hello, World!')"
     ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [x] DONE Layer in Node.js into the base development image
* [x] DONE Layer in Claude Code.
* [ ] I haven't figured out if the build being so slow (over 2 min) is going to get annoying and what I can/should do about caching... doesn't matter yet. Also I might need to cache bust just in general (I guess that's why I added --no-cache optional flag in the nushell script)
* [ ] Consider BuildKit LLB, and/or Dagger. I'd like to see what's possible. I'd like to fuse the downloading/untarring that can happen outside the container, and the instructions for copying it into the container, in the same program/project for cohesion. I'd just like to see what's possible. I'd really like to see if I can write some code that cache-busts based on the hash of the scripts we copy in. One thing I think is really neat about Docker/containers is the permanence of setting env vars, instead of having to bootstrap that from the shell. Doing it earlier than shell is nice.
* [x] DONE (This is causing problems for the Claude Code install; so need to address it) I need to re-think some of root/user stuff. Install Rustup/Cargo as root is kind of obnoxious because now my Cargo bin is in /usr/local/bin so when 'me' user tries to build a project it won't have write access to put the binary there.
* [ ] Consider the idea: can I get away with saving containers in a stateful way? Instead of saving images? Is there a compressed workflow hidden somewhere in here? Now I'm thinking about putting DevContainer's style instructions/Dockerfile in the `.my` directory and using that by convention.
* [ ] Define an agentic runbook (instructions in a prompt + scripts) to find latest versions of deps and update them in our code 
* [ ] Consider sandboxing/LSM stuff (e.g. Landlock) similar to what I did with seatbelt. I'd like the exec tool (the shell it uses is configurable I think) to be some wrapper executable that self-sandboxes bash
* [ ] Layer in my own Nu scripts. A pre-req to this will be splitting out my macOS-specific stuff. Shouldn't be too crazy.
* [ ] Get my rules MCP server in the image, and also my rules files.
