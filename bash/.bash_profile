export CLICOLOR=1

export PATH="$PATH:$HOME/.local/bin"

# I don't need Homebrew auto-updates. I don't want the hint noise. Don't send telemetry.
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_ANALYTICS=1

# Add the JetBrains shell scripts directory to your path so you can launch the IDEs or launch the diff tool from the
# commandline. Usually, I do "idea ." to open the current directory in Intellij.
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# Add the Sublime Text launcher command to the PATH so that you can conveniently execute commands like `subl ~/.bashrc`.
export PATH="$PATH:/Applications/Sublime Text.app/Contents/SharedSupport/bin"

# Rust toolchain
export PATH="$PATH:$HOME/.cargo/bin"

# Docker
export PATH="$PATH:$HOME/.docker/bin/"
# Disable the "Use 'docker scan'" message on every Docker build. For reference, see this GitHub issue discussion: https://github.com/docker/scan-cli-plugin/issues/149#issuecomment-823969364
export DOCKER_SCAN_SUGGEST=false

# Add Go binaries to the PATH.
export PATH="$PATH:$HOME/go/bin"

# HomeBrew
#
# For a long time I was able to avoid executing the brew command because it's so slow (invoke Ruby every time my shell
# starts?). I want try to just hardcode the config here, it barely does anything... but for now keep it.
eval $(/opt/homebrew/bin/brew shellenv)


# 'bash-completion' config
#
# We want to disable the eager-style loading of completion scripts (v1 era), so we set the BASH_COMPLETION_COMPAT_DIR
# environment variable to a non-existent directory. We also need to load the compatibility script. For much more
# information, see the notes in 'bash/README.md' in https://github.com/dgroomes/my-software.

export BASH_COMPLETION_COMPAT_DIR="/disable-legacy-bash-completions-by-pointing-to-a-dir-that-does-not-exist"

shopt -q progcomp
dir=/opt/homebrew/opt/bash-completion@2/

if [[ -d $dir ]]; then
    . "${dir}/share/bash-completion/bash_completion"
    . "${dir}/etc/bash_completion.d/000_bash_completion_compat.bash"
else
    echo >&2 "(warn) bash-completion not loaded."
fi

if [ -f ~/.misc.bash ]; then
    . ~/.misc.bash
fi
