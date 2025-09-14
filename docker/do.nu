const DIR = path self | path dirname

export def build [--no-cache] {
    cd $DIR
    cd my-dev

    mut opts = [--tag my-dev:local]

    if $no_cache {
        $opts = $opts | append "--no-cache"
    }

    docker build ...$opts .
}

export def run [] {
    docker run --name my-dev --init --rm --detach my-dev:local
    docker exec --interactive --tty my-dev nu
}

export def stop [] {
    docker stop my-dev
}
