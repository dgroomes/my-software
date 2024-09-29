export def build [] {
    cd $env.DO_DIR

    gw --quiet installDist
}

export def run [] [string -> string] {
    cd $env.DO_DIR

    $in | ./build/install/java-body-omitter/bin/java-body-omitter
}

export def install [] {
    cd $env.DO_DIR

    ln -sf ('build/install/java-body-omitter/bin/java-body-omitter' | path expand) ~/.local/bin/java-body-omitter
}
