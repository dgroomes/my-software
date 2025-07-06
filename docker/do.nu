const DIR = path self | path dirname

export def build-my-dev [--no-cache] {
    cd $DIR
    cd my-dev

    mut opts = [
        --tag my-dev:local
        --file my-dev.Dockerfile
    ]

    if $no_cache {
        $opts = $opts | append "--no-cache"
    }

    docker build ...$opts .
}

export def run-my-dev [] {
    cd $DIR
    cd my-dev
    docker run --rm -it my-dev:local
}
