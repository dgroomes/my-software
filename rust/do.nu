const DIR = path self | path dirname

export def test [] {
    cd $DIR
    cargo test
}

export def --wrapped "run my-fuzzy-finder" [...args] {
    let _in = $in
    cd $DIR
    if ($_in | is-empty) {
        cargo run --quiet --package my-fuzzy-finder-rs -- ...$args
    } else {
        $_in | (cargo run --quiet --package my-fuzzy-finder-rs -- ...$args)
    }
}

export def build [] {
    cd $DIR
    mkdir bin
    cargo build --release --package my-fuzzy-finder-rs
    cp target/release/my-fuzzy-finder-rs bin/my-fuzzy-finder-rs
}

export def install [] {
    cd $DIR
    cargo install --path my-fuzzy-finder --force
}
