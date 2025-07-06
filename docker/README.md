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
* [ ] Create a "claude-code" image. Or rather, create Nu scripts that install Claude Code and dependencies. I guess I'm not sure if I want to formalize a bunch of Dockerfiles. Can I get away with saving containers in a stateful way? Instead of saving images? I don't really know. Like for a new project, I could create a new container from my base, and then boostrap all the deps I want. Maybe that will take a long time to install things like Node? Hmmm... Or maybe all the "big things" should go in the base image for speed, and the little packages (like npm packages) can be installed on-demand.
* [ ] I haven't figured out if the build being so slow (over 2 min) is going to get annoying and what I can/should do about caching... doesn't matter yet. Also I might need to cache bust just in general (I guess that's why I added --no-cache optional flag in the nushell script)
* [ ] There has to be some other way to script out building a Docker image than Dockerfiles. There is like a Go API right?
