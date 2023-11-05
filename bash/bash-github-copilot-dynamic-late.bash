# This file does configuration and initialization work related to the GitHub Copilot CLI.
# See https://www.npmjs.com/package/@githubnext/github-copilot-cli
#
# This script should be executed and the output should be evaluated ('eval') by your .bashrc.
# This script is designed to be pre-bundled by 'bb'.

# Check if the GitHub Copilot CLI is installed.
if ! command -v github-copilot-cli &>/dev/null; then
  echo >&2 "GitHub Copilot CLI is not installed. Please install it with 'npm install -g @githubnext/github-copilot-cli'."
  echo >&2 "GitHub Copilot aliasing will NOT be included in the bb-bundled .bashrc file at this time."
else
  github-copilot-cli alias -- "$0"
fi
