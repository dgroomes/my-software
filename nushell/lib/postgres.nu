# Activate a specific version of Postgres that's already installed as a Homebrew keg.
#
# By "activate", we need to adapt the PATH to include the directory containing all the Postgres executables like
# "pg_ctl", "psql", "pg_dump", etc. And, we need to set the environment variable "PGDATA" to the convention data
# directory (e.g. "/opt/homebrew/var/postgresql@16").
export def --env activate-postgres [version: string] {
    # Let's expand to, for example, "postgresql@16"
    let at_postgresql = $"postgresql@($version)"

    let result = brew --prefix $at_postgresql | complete
    if ($result.exit_code != 0) {
        error make --unspanned { msg: ("Something unexpected happened while running the 'brew --prefix' command." + (char newline) + $result.stderr) }
    }

    let keg_dir = $result.stdout | str trim
    let bin_dir = [$keg_dir "bin"] | path join
    if not ($bin_dir | path exists) {
        error make --unspanned { msg: ($"Expected to find a 'bin' directory at '($bin_dir)' but that directory does not exist.") }
    }

    # Now do the same for the data directory (PGDATA)
    let result2 = brew --prefix | complete
    if ($result2.exit_code != 0) {
        error make --unspanned { msg: ("Something unexpected happened while running the 'brew --prefix' command." + (char newline) + $result.stderr) }
    }

    let prefix = $result2.stdout | str trim
    let data_dir = [$prefix "var" $at_postgresql] | path join
    if not ($data_dir | path exists) {
        error make --unspanned { msg: ($"Expected to find a Postgres data directory at the conventional location '($data_dir)' but that directory does not exist.") }
    }

    # Deactivate/activate
    $env.PATH = ($env.PATH | where $it !~ "postgresql@")
    $env.PATH = ($env.PATH | prepend $bin_dir)
    $env.PGDATA = $data_dir
    # And for convenience, let's set "PGDATABASE" to "postgres" because that's the default database. When this is
    # set, we can just use "psql" without any connection-specific arguments: no need to specify username, database, or
    # host. Very neat.
    $env.PGDATABASE = "postgres"
}
