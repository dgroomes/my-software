const DIR = path self | path dirname

export def test [] {
    cd $DIR
    cargo test --manifest-path ../rust/my-fuzzy-finder/Cargo.toml
    go test './...'
}

export def --wrapped "run my-fuzzy-finder" [...args] {
    # For some reason, the 'cd' screws things up so we can capture 'in' into another variable. Is 'in' considered a stream
    # data type at this point or are we just reading all of stdin and saving as a string?
    let _in = $in
    cd $DIR
    if ($_in | is-empty) {
        cargo run --quiet --manifest-path ../rust/my-fuzzy-finder/Cargo.toml -- ...$args
    } else {
        $_in | (cargo run --quiet --manifest-path ../rust/my-fuzzy-finder/Cargo.toml -- ...$args)
    }
}

export def build [] {
    cd $DIR
    mkdir bin
    go build -o bin './...'
    cargo build --release --manifest-path ../rust/my-fuzzy-finder/Cargo.toml
    cp ../rust/my-fuzzy-finder/target/release/my-fuzzy-finder bin/my-fuzzy-finder
}

export def install [] {
    cd $DIR
    go install './...'
    cargo install --path ../rust/my-fuzzy-finder --force
}
