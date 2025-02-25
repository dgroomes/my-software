# Activate a version of my personal Homebrew formulas: OpenJDK, Node.js, etc.
do --env {
    let default_java = 21
    let default_node = "23"
    let default_postgres = "17"
    try { activate-my-open-jdk $default_java } catch { print "(warn) A default OpenJDK was not activated." }
    try { activate-my-node $default_node } catch { print "(warn) A default Node.js was not activated." }
    try { activate-postgres $default_postgres } catch { print "(warn) A default Postgres was not activated." }
}
