const DIR = path self | path dirname

export def build-my-nushell [--no-cache] {
    cd $DIR

    mut opts = [
        --tag my-nushell
        --file my-nushell.Dockerfile
    ]

    if $no_cache {
        $opts = $opts | append "--no-cache"
    }

    docker build ...$opts .
}

export def run-my-nushell [] {
    cd $DIR
    docker run --rm -it my-nushell
}
