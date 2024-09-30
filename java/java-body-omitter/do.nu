export def test [] {
    cd $env.DO_DIR

    gw test
}

export def build [] {
    cd $env.DO_DIR

    gw --quiet installDist
}

export def run [] [string -> string] {
    cd $env.DO_DIR

    $in | ./build/install/java-body-omitter/bin/java-body-omitter
}

export def run-daemon [] {
    cd $env.DO_DIR

    ./build/install/java-body-omitter/bin/java-body-omitter --daemon
}

export def install [] {
    cd $env.DO_DIR

    ln -sf ('build/install/java-body-omitter/bin/java-body-omitter' | path expand) ~/.local/bin/java-body-omitter
}

export def send [] {
    let result = $in | nc -U /tmp/java-body-omitter.socket | complete

    if $result.exit_code != 0 {
        print "Something went wrong when sending the Java snippet to the omitter program."
        print $result
        print $result.stderr
    }

    $result.stdout
}
