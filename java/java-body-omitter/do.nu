const DIR = path self | path dirname

export def test [] {
    cd $DIR

    gw test
}

export def gen [] {
    cd $DIR

    # I tried '--debug'  and '--verbose' but it doesn't show much. It prints some debugging information about the Go
    # process (the 'buf' CLI is Go) but does not describe anything about the underlying calls to 'protoc'. I really
    # need to be able to debug and see the exact '.proto' content that is passed to 'protoc'.
    buf generate --path ../../proto/java_body_omitter
}

export def build [] {
    cd $DIR

    gw --quiet installDist
}

export def run [--daemon --protobuf]: [string -> string] {
    cd $DIR

    let args = [(if $daemon { "--daemon" }) (if ($protobuf) { "--protobuf" })] | compact
    $in | ./build/install/java-body-omitter/bin/java-body-omitter ...$args
}

export def run-daemon [] {
    cd $DIR

    ./build/install/java-body-omitter/bin/java-body-omitter --daemon
}

export def install [] {
    cd $DIR

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
