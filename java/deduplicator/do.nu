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
    let exe = "./build/install/deduplicator/bin/deduplicator"
    if not ($exe | path exists) {
        print "Executable not found. Did you run 'build'?"
        return
    }

    $env.MIN_CANDIDATE_LENGTH = $min_length | into string
    $doc | run-external $exe
}

export def install [] {
    cd $DIR
    ln -sf ('build/install/deduplicator/bin/deduplicator' | path expand) ~/.local/bin/deduplicator
}

# I want to understand where the slowness is. 90% sure it's when building the suffix array. So apply the deduplicator
# over an increasing size of corpus and time it. Update: yes the SA is slow but also consolidating ranges slows as well.
export def benchmark [] {
    cd $DIR

    let full_project_str = do {
      # cd ../..
      cd ~/repos/opensource/kafka
      fd -t f | where (is-text-file) | each { open --raw $in } | str join "\n"
    }

    print $"Full project string length: ($full_project_str | str length | comma-per-thousand)"

    let case_sizes = [
        100000
        1000000
        2000000
        3000000
    ]

    for i in $case_sizes {
        let c = $full_project_str | str substring 0..<$i
        let d  = timeit { $c | run --min-length 4 | str length }
        print $"De-duplicating ($c | str length | comma-per-thousand) characters took ($d)\n\n"
    }

    return
}
