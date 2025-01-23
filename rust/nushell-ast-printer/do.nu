const DO_DIR = (path self | path dirname)

export def --wrapped run [...args] {
    let _in = $in
    cd $DO_DIR
    if ($_in | is-empty) {
        cargo run ...$args
    } else {
        $_in | (cargo run ...$args)
    }
}

export def install [] {
    cd $DO_DIR
    cargo install --path .
}
