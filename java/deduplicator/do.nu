const DIR = path self | path dirname

export def test [] {
    cd $DIR
    gw test o+e> test.log
}

export def build [] {
    cd $DIR
    gw --quiet installDist
}

export def run [--min-length: int]: string -> string {
    cd $DIR
    let doc = $in
    $env.MIN_CANDIDATE_LENGTH = $min_length | into string
    $doc | ./build/install/deduplicator/bin/deduplicator
}

export def install [] {
    cd $DIR
    ln -sf ('build/install/deduplicator/bin/deduplicator' | path expand) ~/.local/bin/deduplicator
}
