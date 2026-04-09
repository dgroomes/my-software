# SDR: Linux VM Dev Box

The decision is that I intend to use a Linux VM as a "dev box".


## Overview

I'm having success with Cursor Cloud agents, and I'm seeing promise in using them more. They run in an Ubuntu Firecracker VM in AWS, and they were surprisingly capable of bootstrapping enough of a development environment to accommodate many aspects of `my-software`. A number of toolchains were pre-installed, but they easily figured out how to install Nushell and adapt my Homebrew formula for Homebrew on Linux.

But that was still an ad hoc process. I want to formalize it in instructions, scripts, and more, and version control that work in `my-software`.

Furthermore, I can run this Linux VM as a guest VM on my Mac. I've explored this a decent amount with Tart, but I'm still working out the details. I want to be able to run nested virtualization when possible. Along the same lines, I want control over the outer VM instead of delegating that to Docker Desktop or trying to cram "dev boxes" into containers confined by Docker, cgroups, and the opaque machinery of Docker Desktop. I still like Docker, but I'm not going to let Docker Desktop, and onerous patterns like Docker-in-Docker, restrict my freedom to have a dev box the way I need it.

UPDATE: I think qemu is a better fit for me. I had naively assumed qemu isn't modern in light of the Virtualization.Framework. I've since become educated that qemu supports the Hypervisor.Framework which is itself modern and just a lower level building block behind VF. Plus, qemu is extremely rich, well understood, etc. I even explored QMP. So neat. qemu is an ffmpeg.
