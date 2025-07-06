# Early system setup stuff: installing apt packages and creating the 'me' user.
#
# The 'apt' package management stuff is predominantly the privilege of the root user. We will run this script as root
# early in the Dockerfile.
#
# By contrast, the common wisdom for language-specific package management toolchains (Cargo, npm, etc.) is to run them
# as the user.
#
# This contrast is an arbitrary difference I don't need to resolve. Let's just go with the flow. I'm tempted to either
# push the language-specific package management stuff up to the root (although this will create inconvenience downstream
# for development work with installing temp/local Cargo/npm/Go packages). And, I'm tempted to push the apt package down
# to the user (there is precedent for this, I think, although I don't know much about it in Linux world). For now, go
# with the flow.

set -euo pipefail

apt-get update

# Let's generally follow the list of packages that Anthropic downloads in their own Dockerfile for Claude Code. The
# Claude Code system prompt suggests to the LLM to use some of these tools, and some are just common wisdom suggestions
# from the Anthropic folks. See https://github.com/anthropics/claude-code/blob/397442ddf5be3593eab406478051165a0e7eae80/.devcontainer/Dockerfile#L7
apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  fzf \
  gh \
  git \
  jq \
  pkg-config \
  tini

# Create unprivileged user
#
# Like my own strategy on macOS, I'll keep Bash as the login/default shell. I don't want to even try running things
# like Claude Code from Nushell and I don't want to coerce the LLM to execute Nu commands; it has little idea about that
# in its training data. And I think Claude Code implements a lot of Bash/Zsh-specific idiosyncrasies. Let's keep things
# compatible.
useradd -m -s /bin/bash me
