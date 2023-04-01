# My strategy in the .bash_profile is not to define much stuff (aliases, functions) but instead to source files like
# `~/.bashrc` and other specialized Bash scripts. By doing so, we delegate complexity out of this file and have the
# ability to ignore/benchmark specific chunks of "shell initialization stuff".

# 'current_time' is taken directly from this great project: https://github.com/colindean/hejmo/blob/0f14c6d00c653fcbb49236c4f2c2f64b267ffb3c/dotfiles/bash_profile#L13
current_time() {
  # macos date doesn't provide resolution greater than seconds
  # gdate isn't on the path yet when we need this but *almost*
  # assuredly perl is and it loads faster than anything else
  # https://superuser.com/a/713000
  perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time()*1000)'
}

# 'failure' is taken directly from this great project: https://github.com/colindean/hejmo/blob/0f14c6d00c653fcbb49236c4f2c2f64b267ffb3c/dotfiles/bash_profile#L21
# trap failures during startup more, uh, grandiloquently
failure() {
  local lineno=$2
  local fn=$3
  local exitstatus=$4
  local msg=$5
  local lineno_fns=${1% 0}
  if [[ "$lineno_fns" != "0" ]] ; then
    lineno="${lineno} ${lineno_fns}"
  fi
  echo "${BASH_SOURCE[1]}:${fn}[${lineno}] Failed with status ${exitstatus}: $msg"
}

trap 'failure "${BASH_LINENO[*]}" "$LINENO" "${FUNCNAME[*]:-script}" "$?" "$BASH_COMMAND"' ERR

# We use this file to record how long it took to execute (i.e. "timing") each Bash script that we source.
TIMINGS="$HOME/.bash_source_timings.tsv"
> "$TIMINGS"

# Source a Bash script and record the timing.
source_and_time() {
  local script="$1"
  local load_start load_end load_duration

  load_start=$(current_time)
  source "$script"
  load_end=$(current_time)
  load_duration=$((load_end - load_start))

  echo -e "$script\t$load_duration" >> "$TIMINGS"
}

# These are the Bash scripts that we want to "source into our shell" to superpower our shell experience.
#
# The order is important. Sourcing 'bash-function.bash' should come first so that a function can be invoked from a later
# script. 'bash-aliases.bash' doesn't matter because aliases can only be used in interactive shells (that's why we don't
# uses aliases in scripts right??).
#
# The .bashrc file is sourced last because it's the "catch-all". We can't completely abstract away .bashrc because some
# software installs init/config snippets to it. It would be too annoying to work against that idiom.
files=(
  "$HOME/.config/bash/bash-functions.bash"
  "$HOME/.config/bash/bash-aliases.bash"
  "$HOME/.bashrc"
)

# Source all the scripts.
for i in "${files[@]}"; do
  source_and_time "$i"
done

# (b)ash (s)ource (t)imings
#
# This is a handy alias that we can use to see how long it took to source each script by looking at the
# "bash_source_timings.tsv" file. Where are the slow scripts?
alias bst='cat "$TIMINGS" | sort -n -k 2 | column -t'
