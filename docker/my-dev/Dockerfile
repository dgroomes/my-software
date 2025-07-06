# My Docker image for development. It's designed to include the foundational components and toolchains I need for my
# projects. The heavly lifting is delegated to scripts that are copied into the image and run within the container.

# Let's use a pretty barebones but friendly Linux distribution
FROM debian:12.11-slim

WORKDIR /usr/local/my-dev-install

ENV DEBIAN_FRONTEND=noninteractive

# Bootstrap from Bash to Nushell
COPY 1-rust-and-nushell.bash .
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN ["/bin/bash", "/usr/local/my-dev-install/1-rust-and-nushell.bash"]

# Install Node.js
COPY 2-nodejs.nu .
# The end-user ('me') needs write permissions to the npm global install directory. Let's use a conventional location
# in the user's home directory. Remember, there are no other users designed to be in this container. We can cater to the
# 'me' user exclusively.
ENV NPM_CONFIG_PREFIX=/home/me/.local/npm \
    PATH=/usr/local/node/bin:/home/me/.local/npm/bin:$PATH
RUN ["/usr/local/cargo/bin/nu", "/usr/local/my-dev-install/2-nodejs.nu"]

# Install even more stuff (coming soon)

# Create unprivileged user
#
# Like my own strategy on macOS, I'll keep Bash as the login/default shell. I don't want to even try running things
# like Claude Code from Nushell and I don't want to coerce the LLM to execute Nu commands; it has little idea about that
# in its training data. And I think Claude Code implements a lot of Bash/Zsh-specific idiosyncrasies. Let's keep things
# compatible.
RUN ["useradd", "-m", "-s", "/bin/bash", "me"]
USER me

WORKDIR /home/me/workspace

# I still don't understand exactly why we need things like tini, but I trust that it is useful. I'm just a little
# confused about how the OS sends (or chooses to not send) signals and especially how that relates to PID 1. I just can't
# get a straight answer and example from the LLM. I need to hit the books on that. But let's use it.
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/bin/bash"]
