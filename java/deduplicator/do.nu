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

# Set up the Kafka repo for testing with large corpora.
export def setup-kafka [] {
    cd $DIR
    let my_dir = ".my"
    let repos_dir = $"($my_dir)/repos"
    let kafka_dir = $"($repos_dir)/kafka"

    if not ($my_dir | path exists) {
        print "Creating .my directory..."
        mkdir $my_dir
    }

    if not ($repos_dir | path exists) {
        print "Creating .my/repos directory..."
        mkdir $repos_dir
    }

    if not ($kafka_dir | path exists) {
        print "Cloning Apache Kafka repository (this may take a while)..."
        git clone --depth 1 https://github.com/apache/kafka.git $kafka_dir
        print "Kafka cloned successfully!"
    } else {
        print "Kafka repository already exists at .my/repos/kafka"
    }
}

# Clone the SA-IS reference implementations for study.
export def setup-references [] {
    cd $DIR
    let my_dir = ".my"
    let repos_dir = $"($my_dir)/repos"

    if not ($my_dir | path exists) {
        print "Creating .my directory..."
        mkdir $my_dir
    }

    if not ($repos_dir | path exists) {
        print "Creating .my/repos directory..."
        mkdir $repos_dir
    }

    # Clone the Rust SA-IS port (of Chrome's implementation)
    let sa_is_dir = $"($repos_dir)/sa-is"
    if not ($sa_is_dir | path exists) {
        print "Cloning sa-is (Rust port of Chrome's SA-IS)..."
        git clone https://github.com/oguzbilgener/sa-is.git $sa_is_dir
        print "sa-is cloned successfully!"
    } else {
        print "sa-is already exists at .my/repos/sa-is"
    }

    # Clone Google Research's deduplicate-text-datasets
    let google_dir = $"($repos_dir)/deduplicate-text-datasets"
    if not ($google_dir | path exists) {
        print "Cloning Google Research deduplicate-text-datasets..."
        git clone https://github.com/google-research/deduplicate-text-datasets.git $google_dir
        print "deduplicate-text-datasets cloned successfully!"
    } else {
        print "deduplicate-text-datasets already exists at .my/repos/deduplicate-text-datasets"
    }
}

# Benchmark deduplication on increasingly large corpus sizes.
export def benchmark [] {
    cd $DIR

    let kafka_dir = ".my/repos/kafka"
    if not ($kafka_dir | path exists) {
        print "Kafka not found. Run 'do setup-kafka' first."
        return
    }

    let full_project_str = do {
      cd $kafka_dir
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
