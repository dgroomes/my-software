use zdu.nu err

# Activate a specific version of Postgres that's already installed as a Homebrew keg.
#
# By "activate", we need to adapt the PATH to include the directory containing all the Postgres executables like
# "pg_ctl", "psql", "pg_dump", etc. And, we need to set the environment variable "PGDATA" to the convention data
# directory (e.g. "/opt/homebrew/var/postgresql@16").
export def --env activate-postgres [version: string] {
    # Let's expand to, for example, "postgresql@16"
    let at_postgresql = $"postgresql@($version)"
    let keg_dir = [$env.HOMEBREW_PREFIX "opt" $at_postgresql] | path join

    if not ($keg_dir | path exists) {
        err $"Expected to find formula '($at_postgresql)' but did not."
    }

    let bin_dir = [$keg_dir "bin"] | path join
    if not ($bin_dir | path exists) {
        err $"Expected to find a 'bin' directory at '($bin_dir)' but that directory does not exist."
    }

    # Now do the same for the data directory (PGDATA)
    let data_dir = [$env.HOMEBREW_PREFIX "var" $at_postgresql] | path join
    if not ($data_dir | path exists) {
        err $"Expected to find a Postgres data directory at the conventional location '($data_dir)' but that directory does not exist."
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
