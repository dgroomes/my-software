use std/testing *
use std/assert
use ../scripts/my-git-lib.nu *

@test
def "explicit remote wins" [] {
    assert equal (resolve-remote-from-list [origin upstream] origin) "origin"
}

@test
def "uses only remote" [] {
    assert equal (resolve-remote-from-list [origin]) "origin"
}

@test
def "errors when no remotes" [] {
    assert error { resolve-remote-from-list [] }
}

@test
def "errors when multiple remotes and none selected" [] {
    assert error { resolve-remote-from-list [origin upstream] }
}

@test
def "https remote becomes browser url" [] {
    assert equal (remote-url-to-web-url 'https://github.com/dgroomes/my-software.git') 'https://github.com/dgroomes/my-software'
}

@test
def "https remote without dot git stays clean" [] {
    assert equal (remote-url-to-web-url 'https://github.com/dgroomes/my-software') 'https://github.com/dgroomes/my-software'
}

@test
def "scp style remote becomes browser url" [] {
    assert equal (remote-url-to-web-url 'git@github.com:dgroomes/my-software.git') 'https://github.com/dgroomes/my-software'
}

@test
def "scp style remote without dot git stays clean" [] {
    assert equal (remote-url-to-web-url 'git@github.com:dgroomes/my-software') 'https://github.com/dgroomes/my-software'
}

@test
def "unsupported ssh scheme errors" [] {
    assert error { remote-url-to-web-url 'ssh://git@github.com/dgroomes/my-software.git' }
}
