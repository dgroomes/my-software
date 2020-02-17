# Intellij IDEA diff
ideadiff() {
    if [[ -z "$1" || -z "$2" ]]; then
        echo >&2 "Usage: $0 file1 file2"
        exit 1
    fi
    /Users/davidgroomes/Library/Application\ Support/JetBrains/Toolbox/apps/IDEA-U/ch-0/193.6015.39/IntelliJ\ IDEA.app/Contents/MacOS/idea diff "$1" "$2"
}

# Open the browser to the current Git "remote" URL
gitbrowse() {
    local REMOTE=$(git remote)
    local URL=$(git remote get-url $REMOTE)
    echo "Opening $URL ..."
    open "$URL"
}

# Make a new directory for some "subject".
#
# E.g. `mkdir_subject myexperiment` will create the directory `~/subjects/2020-02-09_myexperiment`
# The "subject" argument is optional.
# E.g. `mkdir_subject` will create the directory `~/subjects/2020-02-09_18-02-05`
function mkdir_subject() {
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
function formatEpoch() {
    if [[ -z "$1" ]]; then
        echo >&2 "Missing argument: 'seconds from Unix epoch'"
        return
    fi
    date -r $1
}

# Format a date/time string from a "milliseconds from the Unix epoch" value. The fractional seconds will be truncated.
# E.g. `formatEpochMilli 1581293097123` is equivalent to `formatEpoch 1581293097`.
function formatEpochMilli() {
    if [[ -z "$1" ]]; then
        echo >&2 "Missing argument: 'milliseconds from Unix epoch'"
        return
    fi
    local S=${1::-3}
    formatEpoch $S
}

# Print the PATH with each entry on a new line
function showpath() {
    tr ':' '\n' <<< "$PATH"
}