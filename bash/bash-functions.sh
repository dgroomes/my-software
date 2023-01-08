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
    local today
    today=$(date +%Y-%m-%d)
    local descriptor
    if [ -z "$1" ]; then
        descriptor=$(date +%H-%M-%S)
    else
        descriptor="$1"
    fi
    local dirname="$HOME/subjects/${today}_${descriptor}"
    mkdir -p "$dirname"
    echo "Created directory: $dirname. Navigating to it."
    cd "$dirname" || return 1
}

# Format a date/time string from a "seconds from the Unix epoch" value
# E.g. `formatEpoch 1581293097` will return 'Sun Feb  9 18:04:57 CST 2020'
formatEpoch() {
    if [[ -z "$1" ]]; then
        echo >&2 "Missing argument: 'seconds from Unix epoch'"
        return 1
    fi
    date -r "$1"
}

# Format a date/time string from a "milliseconds from the Unix epoch" value. The fractional seconds will be truncated.
# E.g. `formatEpochMilli 1581293097123` is equivalent to `formatEpoch 1581293097`.
formatEpochMilli() {
    if [[ -z "$1" ]]; then
        echo >&2 "Missing argument: 'milliseconds from Unix epoch'"
        return 1
    fi
    local S=${1::-3}
    formatEpoch "$S"
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
  DEST="$(find ~/repos -type d -maxdepth 2 -mindepth 2 -not -path '*./*' | fzf --exact)"
  EXIT_STATUS=$?
  [[ $EXIT_STATUS -eq 0 ]] && cd "$DEST" || return 1
}

# Start (and initialize if needed) a Postgres server instance.
#
# By convention, the data directory "/usr/local/pgsql/data" is used. The Postgres official docs use this directory in
# their examples. See https://www.postgresql.org/docs/current/creating-cluster.html
pgStart() {
  if [[ ! -d /usr/local/pgsql/data ]]; then
    echo "The '/usr/local/pgsql/data' directory does not exist. Creating it and initializing it ..."
    mkdir /usr/local/pgsql/data

    pg_ctl -D /usr/local/pgsql/data initdb
    _pgConfCustom

    pg_ctl -D /usr/local/pgsql/data start
    psql postgres -c 'create role postgres with login superuser'
  else
    pg_ctl -D /usr/local/pgsql/data start
  fi
}

# Stop the Postgres server instance
pgStop() {
  pg_ctl -D /usr/local/pgsql/data stop
}

# Completely destroy the contents of the local Postgres data directory.
# WARNING: this will delete all of the data!
#
# For convenience, this function will also:
#   * Stop the Postgres instance if it is already running
#   * Initialize a new Postgres data directory
#   * Start a Postgres instance
#   * Define a role named 'postgres' (this role is often used as a convention by programs and apps).
pgDestroy() {
  pg_ctl -D /usr/local/pgsql/data stop

  rm -rf /usr/local/pgsql/data
  mkdir -p /usr/local/pgsql/data

  pg_ctl -D /usr/local/pgsql/data initdb
  _pgConfCustom
  pg_ctl -D /usr/local/pgsql/data start

  psql postgres -c 'create role postgres with login superuser'
}

# Replace some properties in the postgresql.conf file that are tuned for a local development environment where durability
# is not needed! Also, increase the memory settings.
#
# For reference, see https://stackoverflow.com/a/9407940
_pgConfCustom() {
  local CONF=/usr/local/pgsql/data/postgresql.conf

  # Backup the original conf file contents into a new file with extension '.bak'. Make several substitutions.
  sed -i.bak \
   -e "/^#fsync = on/             s/#fsync = on/fsync = off/" \
   -e "/^#full_page_writes = on/  s/#full_page_writes = on/full_page_writes = off/" \
   -e "/^shared_buffers/          s/128MB/4GB/" \
   -e "/^#work_mem = 4MB/         s/#work_mem = 4MB/work_mem = 1GB/" \
   "$CONF"
}

# Show the MongoDB logs
mongoLog() {
  tail +1f "/usr/local/mongodb/mongod.log"
}

# Start a MongoDB server instance using the 'mongod' command
mongoStart() {

  local log_file=/usr/local/mongodb/mongod.log
  # Truncate the existing log file.
  true > "$log_file"

  # Start the server as a daemon process. Use a custom data directory and log location. Do NOT rotate the logs (I don't
  # need to retain old logs)
  mongod \
    --dbpath "/usr/local/mongodb/data" \
    --fork \
    --logpath "$log_file" \
    --logRotate reopen \
    --logappend \
    --bind_ip 127.0.0.1

  # Wait for it to become ready.
  sleep 2

  # Disable the monitoring advertisement when starting a 'mongo' shell session
  mongo --quiet << EOF
  db.disableFreeMonitoring()
EOF
}

# Stop MongoDB if it is running
mongoStop() {
  mongo --quiet admin << EOF
    db.shutdownServer()
EOF
}

# Completely destroy the existing MongoDB data directory then start a MongoDB server instance using the 'mongod' command
mongoDestroy() {
  if [[ ! -d "/usr/local/mongodb" ]]; then
    echo >&2 "MongoDB base directory does not exist! '/usr/local/mongodb'"
    return 1
  fi

  # Stop MongoDB if it is already running
  mongoStop

  # DESTROY ALL EXISTING DATA!
  rm -rf "/usr/local/mongodb/data"
  mkdir -p "/usr/local/mongodb/data"

  mongoStart
}

# MongoDB. Execute the "mongo" command with the "quiet" option
mon() {
  mongo --quiet "$@"
}

# Start a Python3 server in the current directory.
#
# The bind address is intentionally set to the "127.0.0.1" IPV4 address instead of the default value which is the "::"
# IPV6 address. This is because iTerm recognizes the former one as a URL which you can conveniently "Cmd + click" into
# while it doesn't recognize the latter as a URL.
httpServe() {
  python3 -m http.server --bind 127.0.0.1
}

# Obtain the absolute path of a file
#
# For example, given the command
#
# $ filepath ../README.md
#
# It will print:
#
# /Users/davidgroomes/repos/personal/my-config/README.md
#
# This function is adapted from https://stackoverflow.com/a/21188136. See the question and litany of different answers.
# Yes, it is startling that a simple and reasonable task like "Find the absolute path to this file" can be answered only
# by a long list of circuitous and partially effective solutions. That is the state of the most popular shell, even in
# 2022.
filepath() {
  local relative_file="$1"
  echo "$(cd "$(dirname "$relative_file")" && pwd)/$(basename "$relative_file")"
}

# `whichLong` is like `which` but it prints a long-form description of the command-under-inspection.
#
# For example, you might use `which` to find out where the `gs` command is coming from. It looks like this:
#
# $ which gs
# /usr/local/bin/gs
#
# That's not super useful because `/usr/local/bin/gs` is actually a symlink, which you can't tell from the short-form
# output.
#
# Which `whichLong`, you can find more information about the file that represents the command-under-inspection:
#
# $ whichLong gs
# lrwxr-xr-x  1 davidgroomes  admin    35B Jul  2 14:40 /usr/local/bin/gs -> ../Cellar/ghostscript/9.56.1/bin/gs
#
# Great, we've learned something more useful! It turns out 'gs' is a program called "GhostScript" and it was installed
# via HomeBrew (probably as a transitive dependency of another HomeBrew-managed package).
whichLong() {
  local command="$1"

  if [ -z "$command" ]; then
    echo >&2 "Missing argument: please pass the name of a command."
    return 1
  fi

  ls -lh "$(which "$command")"
}
