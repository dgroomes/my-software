export def --wrapped run [...args] {
    let _in = $in
    cd $env.DO_DIR
    if ($_in | is-empty) {
        cargo run ...$args
    } else {
        $_in | (cargo run ...$args)
    }
}

export def install [] {
    cd $env.DO_DIR
    cargo install --path .
}
