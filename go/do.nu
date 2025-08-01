const DIR = path self | path dirname

export def test [] {
    cd $DIR
    go test './...'
}

export def --wrapped "run my-fuzzy-finder" [...args] {
    # For some reason, the 'cd' screws things up so we can capture 'in' into another variable. Is 'in' considered a stream
    # data type at this point or are we just reading all of stdin and saving as a string?
    let _in = $in
    cd $DIR
    if ($_in | is-empty) {
        go run my-software/pkg/my-fuzzy-finder ...$args
    } else {
        print "in is not empty"
        $_in | (go run my-software/pkg/my-fuzzy-finder ...$args)
    }
}

export def build [] {
    cd $DIR
    mkdir bin; go build -o bin  './...'
}

export def install [] {
    cd $DIR
    go install './...'
}
