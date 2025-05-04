const DIR = path self | path dirname

export def test [] {
    cd $DIR
    # Redirection is hard in any shell and Nushell is no exception. I'm running into an issue where I'd like to use my
    # 'gw' wrapped command but when I try to redirect the output (both stdout and stdout) to a file I get 'piping stderr
    # only works on external commands'.
    #
    # An easy workaround here is just use 'gradlew' directly. Super easy. But I am curious how Nushell will eventually
    # incorporate a more full model of stderr. See https://github.com/nushell/nushell/issues/12686#issuecomment-2081250589
    #
    # Also reference: https://www.nushell.sh/book/stdout_stderr_exit_codes.html and https://www.nushell.sh/lang-guide/chapters/pipelines.html
    ../gradlew test o+e>| tee { save -f test.log }
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
