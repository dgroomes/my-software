const DO_DIR = (path self | path dirname)

export def test [] {
    cd $DO_DIR
    go test './...'
}

export def --wrapped "run my-fuzzy-finder" [...args] {
    # For some reason, the 'cd' screws things up so we can capture 'in' into another variable. Is 'in' considered a stream
    # data type at this point or are we just reading all of stdin and saving as a string?
    let _in = $in
    cd $DO_DIR
    if ($_in | is-empty) {
        go run my-software/pkg/my-fuzzy-finder ...$args
    } else {
        print "in is not empty"
        $_in | (go run my-software/pkg/my-fuzzy-finder ...$args)
    }
}

export def "run go-body-omitter" [] {
    let _in = $in
    cd $DO_DIR
    $_in | go run my-software/pkg/go-body-omitter
}

export def "run posix-nushell-compatibility-checker" [] {
    let _in = $in
    cd $DO_DIR
    $_in | go run my-software/pkg/posix-nushell-compatibility-checker
}

export def build [] {
    cd $DO_DIR
    mkdir bin; go build -o bin  './...'
}

export def install [] {
    cd $DO_DIR
    go install './...'
}
