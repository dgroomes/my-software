# This file should be sourced by .bash_profile or .bashrc.
#
# This file does configuration and initialization work related to the 'bash-completion' (version 2) software package.
# Remember, the 'bash-completion' project is not an official part of the Bash project, but basically everyone uses it
# so it is a de facto standard.

# The BASH_COMPLETION_COMPAT_DIR environment variable tells the "bash-completion" program where to find v1 (legacy)
# completions. By default, the value is "/usr/local/etc/bash_completion.d".
#
# After a lot of trial and error, I've come to an unintuitive decision: DO NOT SUPPORT LEGACY COMPLETIONS AT ALL.
# Specifically, I want "bash-completion" to not even consider legacy completion scripts. This is for two reasons. For
# one, "bash-completion" sources legacy scripts eagerly and this is slow. The completion scripts for 'docker', for example,
# take over half a second (roughly). The modern version of "bash-completion" (version 2) does on-demand loading. This is
# much better!
#
# The second reason why I want to disable legacy completions is because they don't even matter? Confusingly, I found that
# just copying the 'docker' completion script from the legacy directory to the modern directory "just works". I'm tempted
# to figure out why and how, but honestly I've spent way too much time on this and I'm beyond the point of diminished
# returns.
#
# So, to effectively disable legacy completions, I set the BASH_COMPLETION_COMPAT_DIR environment variable to a non-existent directory.
export BASH_COMPLETION_COMPAT_DIR="/disable-legacy-bash-completions-by-pointing-to-a-dir-that-does-not-exist"

# This loads the 'bash-completion' program itself, but importantly, the individual completions should not be loaded
# thanks to the BASH_COMPLETION_COMPAT_DIR trick above.
#
# This exact line of code is from the 'caveats' section of the 'bash-completion' HomeBrew formula.
# See https://github.com/Homebrew/homebrew-core/blob/fbf8af0430f9664210639dab578609e95fa065c9/Formula/bash-completion%402.rb#L53
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"
