# My Docker image for development. It's designed to include the foundational components and toolchains I need for my
# projects. The heavly lifting is delegated to scripts that are copied into the image and run within the container.

# Let's use a pretty barebones but friendly Linux distribution
FROM debian:12.11-slim

WORKDIR /usr/local/my-dev-install

ENV DEBIAN_FRONTEND=noninteractive

COPY 1-root-stuff.bash .
RUN ["bash", "1-root-stuff.bash"]

# Now we cross the root/user divide. We're seeing the root/user tension here. The earlier workspace is writeable by root,
# but not by the 'me' user. I could make it writeable to the 'me' user, but it's a code smell making anything in /usr or
# the like writeable by a non-root user. So let's just create a new workspace for the 'me' user.
USER me
WORKDIR /home/me/.local/my-dev-install

# Bootstrap from Bash to Nushell
#
# Remember, there are no other users designed to be in this container. Let's cater everything (e.g. install locations)
# to the 'me' user exclusively.
#
# Let's install the Rust toolchain in a conventional location in the user's home directory: "~/.local".
COPY 2-rust-and-nushell.bash .
ENV RUSTUP_HOME=/home/me/.local/rustup \
    CARGO_HOME=/home/me/.local/cargo \
    PATH=/home/me/.local/cargo/bin:$PATH
RUN ["bash", "2-rust-and-nushell.bash"]

# Install Node.js
COPY 3-nodejs.nu .
ENV NPM_CONFIG_PREFIX=/home/me/.local/npm \
    PATH=/home/me/.local/node/bin:/home/me/.local/npm/bin:$PATH
RUN ["nu", "3-nodejs.nu"]

# After everthing is installed, land the user into a starting-point directory where they can focus on their work.
WORKDIR /home/me/workspace

# I'm trying out a do-nothing entrypoint, which means the container is only useful when you 'exec' additional processes
# in it. For me, that should work. I'm building Nushell scripting around this workflow to quickly create and attach to
# the development containers. I don't need to rely on the container entrypoint as the actual doorway I use to start
# work in the container.
ENTRYPOINT ["sleep", "infinity"]
