# Build a Docker image with the Rust toolchain and Nushell.
#
# My vision with this is to use this Dockerfile to bootstrap an environment where I can then script out some stuff in
# Nu scripts and layer in more and more project-specific dependencies. We'll see.
#
# Like my own strategy on macOS, I'll keep Bash as the login/default shell. I don't want to even try running things
# like Claude Code from Nushell and I don't want to coerce the LLM to execute Nu commands; it has little idea about that
# in its training data. And I think Claude Code implements a lot of Bash/Zsh-specific idiosyncrasies. Let's keep things
# compatible.

# Let's try to use a pretty barebones but friendly Linux distribution. We'll use Debian "slim".
# See https://hub.docker.com/_/debian
FROM debian:12.11-slim

# Choose the Nu release and the Rust toolchain it expects
ARG NU_VERSION=0.105.1
# Make sure to align the version of Nushell with the version of the Rust toolchain that it requires
# See https://github.com/nushell/nushell/blob/0.105.1/rust-toolchain.toml#L19
ARG RUST_TOOLCHAIN=1.85.1

ENV DEBIAN_FRONTEND=noninteractive \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

# 1. System build prerequisites
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates build-essential pkg-config tini && \
    rm -rf /var/lib/apt/lists/*

# 2. Install the exact Rust toolchain components we need via rustup's "minimal" profile
RUN curl -sSf https://sh.rustup.rs | sh -s -- -y \
      --profile minimal --default-toolchain ${RUST_TOOLCHAIN}

# 3. Compile Nushell from crates.io, locked for reproducibility
RUN cargo install nu --locked --version ${NU_VERSION}

# Unprivileged default user
RUN useradd -m -s /bin/bash me
USER me
WORKDIR /home/me

# I still don't understand exactly why we need things like tini, but I trust that it is useful. I'm just a little
# confused about how the OS sends (or chooses to not send) signals and especially how that relates to PID 1. I just can't
# get a straight answer and example from the LLM. I need to hit the books on that. But let's use it.
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/bin/bash"]
