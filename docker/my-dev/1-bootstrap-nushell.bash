# This script installs Rust and Nushell in a Docker container. It is designed to bootstrap the environment from Bash to
# Nushell so that we may only deal with Nushell for the remaining installation scripts.
#
# It's important to synchronize the version of Nushell with the Rust toolchain it expects.
# See https://github.com/nushell/nushell/blob/0.105.1/rust-toolchain.toml#L19 and always update this link when upgrading
# to a new version of Nushell.

set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends curl ca-certificates build-essential pkg-config tini xz-utils

curl -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.85.1

cargo install nu --locked --version 0.105.1
