use std/assert
use ../scripts/my-git-lib.nu *

# Warning: unedited AI output.

def main [] {
    let test_commands = (
        scope commands
        | where ($it.type == "custom") and ($it.name | str starts-with "test ")
        | get name
        | each { |test| [$"print 'Running test: ($test)'", $test] }
        | flatten
        | str join "; "
    )

    nu --commands $"source ($env.CURRENT_FILE); ($test_commands)"
}

def "test explicit remote wins" [] {
    assert equal (resolve-remote-from-list [origin upstream] origin) "origin"
}

def "test uses only remote" [] {
    assert equal (resolve-remote-from-list [origin]) "origin"
}

def "test errors when no remotes" [] {
    assert error { resolve-remote-from-list [] }
}

def "test errors when multiple remotes and none selected" [] {
    assert error { resolve-remote-from-list [origin upstream] }
}

def "test https remote becomes browser url" [] {
    assert equal (remote-url-to-web-url 'https://github.com/dgroomes/my-software.git') 'https://github.com/dgroomes/my-software'
}

def "test https remote without dot git stays clean" [] {
    assert equal (remote-url-to-web-url 'https://github.com/dgroomes/my-software') 'https://github.com/dgroomes/my-software'
}

def "test scp style remote becomes browser url" [] {
    assert equal (remote-url-to-web-url 'git@github.com:dgroomes/my-software.git') 'https://github.com/dgroomes/my-software'
}

def "test scp style remote without dot git stays clean" [] {
    assert equal (remote-url-to-web-url 'git@github.com:dgroomes/my-software') 'https://github.com/dgroomes/my-software'
}

def "test unsupported ssh scheme errors" [] {
    assert error { remote-url-to-web-url 'ssh://git@github.com/dgroomes/my-software.git' }
}
