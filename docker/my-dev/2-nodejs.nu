# Install Node.js by downloading pre-built binaries directly from the official Node.js hosted location.
#
# I'm preferring to handroll this installation because I've already done this for my macOS setup, and I've found it
# enabling for switching between Node.js versions without needing to use a version manager like nvm. Also, the download
# and installation process is pretty compact, so the maintenance overhead is fine. I don't need multiple versions right
# now, and I may even just go to a package manager, but not sure.
#
# The Node.js download page is friendly: https://nodejs.org/en/download
#
# The direct URL to a specific architecture + version looks like the following, and then also a URL to the SHA256 hashes
# across all architectures for that version:
#   - https://nodejs.org/dist/v22.17.0/node-v22.17.0-linux-arm64.tar.gz
#   - https://nodejs.org/dist/v22.17.0/SHASUMS256.txt

export def main [] {
    let version = "v22.17.0"
    let arch = "linux-arm64"
    let sha = "3e99df8b01b27dc8b334a2a30d1cd500442b3b0877d217b308fd61a9ccfc33d4"

    install-nodejs $version $arch $sha
}

def install-nodejs [version arch sha] {
    let filename = $"node-($version)-($arch).tar.gz"

    let url = $"https://nodejs.org/dist/($version)/($filename)"

    print $"Downloading Node.js ($version) for ($arch)..."
    http get $url | save -f $filename

    let actual_sha = (open $filename --raw | hash sha256)

    if $actual_sha != $sha {
        print $"SHA256 verification failed!"
        print $"Expected: ($sha)"
        print $"Actual:   ($actual_sha)"
        exit 1
    }

    tar -xf $filename

    # Note: by convention, we know that the extracted directory will be named like "node-v22.17.0-linux-arm64"
    let node_dir = $"node-($version)-($arch)"
    mv $node_dir /usr/local/node

    print $"Node.js ($version) installed successfully!"
    print "Verifying installation..."
    node --version
    npm --version
}
