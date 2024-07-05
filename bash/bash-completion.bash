# This file should be sourced by .bash_profile or .bashrc.
#
# This file does configuration and initialization work related to the 'bash-completion' (version 2) software package.
# Remember, the 'bash-completion' project is not an official part of the Bash project, but basically everyone uses it
# so it is a de facto standard.
#
# We want to disable the eager-style loading of completion scripts (v1 era), so we set the BASH_COMPLETION_COMPAT_DIR
# environment variable to a non-existent directory. We also need to load the compatibility script. For much more
# information, see the notes in 'BASH_COMPLETION.md' in https://github.com/dgroomes/my-config.

export BASH_COMPLETION_COMPAT_DIR="/disable-legacy-bash-completions-by-pointing-to-a-dir-that-does-not-exist"

shopt -q progcomp
dir=/opt/homebrew/opt/bash-completion@2/

if [[ -d $dir ]]; then
    . "${dir}/share/bash-completion/bash_completion"
    . "${dir}/etc/bash_completion.d/000_bash_completion_compat.bash"
else
    echo >&2 "(warn) bash-completions not loaded."
fi
