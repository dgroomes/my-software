# Open the browser to the current Git "remote" URL
# Uses GitHub's 'gh' CLI https://github.com/cli/cli
gitBrowse() {
    gh repo view --web
}

# Make a new directory for some "subject".
#
# E.g. `mkdirSubject myexperiment` will create the directory `~/subjects/2020-02-09_myexperiment`
# The "subject" argument is optional.
# E.g. `mkdirSubject` will create the directory `~/subjects/2020-02-09_18-02-05`
mkdirSubject() {
    local today=$(date +%Y-%m-%d)
    local descriptor
    if [ -z "$1" ]; then
        descriptor=$(date +%H-%M-%S)
    else
        descriptor="$1"
    fi
    local dirname="$HOME/subjects/${today}_${descriptor}"
    mkdir -p "$dirname"
    echo "Created directory: $dirname. Navigating to it."
    cd "$dirname"
}

# Format a date/time string from a "seconds from the Unix epoch" value
# E.g. `formatEpoch 1581293097` will return 'Sun Feb  9 18:04:57 CST 2020'
formatEpoch() {
    if [[ -z "$1" ]]; then
        echo >&2 "Missing argument: 'seconds from Unix epoch'"
        return
    fi
    date -r $1
}

# Format a date/time string from a "milliseconds from the Unix epoch" value. The fractional seconds will be truncated.
# E.g. `formatEpochMilli 1581293097123` is equivalent to `formatEpoch 1581293097`.
formatEpochMilli() {
    if [[ -z "$1" ]]; then
        echo >&2 "Missing argument: 'milliseconds from Unix epoch'"
        return
    fi
    local S=${1::-3}
    formatEpoch $S
}

# Print the PATH with each entry on a new line
showPath() {
    tr ':' '\n' <<< "$PATH"
}

# Switch to a project repository.
#
# Uses 'fzf' and 'find' to easily change directories to any of those that are *two levels* below the "~/repos"
# directory. By convention, I like to put my git projects under directories like "~/repos/personal" and
# "~/repos/opensource". So, with this shell function, I can take advantage of that convention and make a quick-switcher
# with 'fzf' and 'find'.
cdRepo() {
  local EXIT_STATUS
  local DEST
  DEST=$(find ~/repos -type d -maxdepth 2 -mindepth 2 -not -path '*./*' | fzf --exact)
  EXIT_STATUS=$?
  [[ $EXIT_STATUS -eq 0 ]] && cd $DEST
}
