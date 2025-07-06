# My Docker image for development. It's designed to include the foundational components and toolchains I need for my
# projects. The heavly lifting is delegated to scripts that are copied into the image and run within the container.

# Let's use a pretty barebones but friendly Linux distribution
FROM debian:12.11-slim

ENV DEBIAN_FRONTEND=noninteractive \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:/usr/local/node/bin:$PATH

COPY 1-bootstrap-nushell.bash /usr/local/my-dev-install/
RUN ["/bin/bash", "/usr/local/my-dev-install/1-bootstrap-nushell.bash"]

COPY 2-everything-else.nu /usr/local/my-dev-install/
RUN ["/usr/local/cargo/bin/nu", "/usr/local/my-dev-install/2-everything-else.nu"]

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
