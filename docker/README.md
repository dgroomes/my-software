# docker

Docker configurations and conventions that support my personal workflows.


## Overview

I generally like to use the native macOS host environment for my development work, and to enjoy the speed, interpretability, and comfort of a native setup. However, virtualization is sometimes a must, and the right tool.

I'm finding this especially true for agentic tools like Claude Code.

This `docker` directory is for me to build up my own conventions, Docker images, and ideas around how Docker fits into my workflow.

I do *not* want to just use Docker for the sake of using it.


## Strategy

I don't like the ergonomics of `Dockerfile` files. I don't like how the ecosystem has chosen to do heavy inheritance-based relationships of "using the Node Docker image for Node apps", or "using the Python Docker image for Python apps".

What if I need both? And what if I want a different upstream component that was earlier baked into the Node image, for example?

I'd much rather inherit from a base Linux distribution image, then layer in the tools I need. As such, I have a `my-nushell` image that uses Debian and layers in Nushell. My vision with this is to layer in Nu scripts that incorporate more and more tools that I need.


## Instructions

Follow these instructions to work with Docker configurations in this directory.

1. Activate the `do.nu` script 
   * ```shell
     do activate
     ```
2. Build the `my-nushell` image
   * ```shell
     do build-my-nushell
     ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [ ] Layer in Node somehow (with the Nu scripts vision I want?) and then maybe that is the base for my "my-dev" image? And the "my-nushell" image is more like a "my-bootstrap" image? As a way to bootstrap out of Dockerfiles? Idk. Seems like it should just be one image.
* [ ] Create a "claude-code" image. Or rather, create Nu scripts that install Claude Code and dependencies. I guess I'm not sure if I want to formalize a bunch of Dockerfiles. Can I get away with saving containers in a stateful way? Instead of saving images? I don't really know. Like for a new project, I could create a new container from my base, and then boostrap all the deps I want. Maybe that will take a long time to install things like Node? Hmmm... Or maybe all the "big things" should go in the base image for speed, and the little packages (like npm packages) can be installed on-demand.
