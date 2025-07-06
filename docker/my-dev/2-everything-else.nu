# WARNING: I haven't even tried this yet. AI sloppy. Have to look at it more closely first.
#
# Install Node.js by downloading pre-built binaries directly from the official Node.js hosted location.
# I'm preferring to handroll this installation because I've already done this for my macOS setup, and I've found it
# enabling for switching between Node.js versions without needing to use a version manager like nvm. Also, the download
# and installation process is pretty compact, so the maintenance overhead is fine.

# Node.js version and architecture configuration
let node_version = "22.17.0"
let arch = "linux-x64"
let filename = $"node-v($node_version)-($arch).tar.xz"

# Hardcoded SHA256 hash for cryptographic verification
let expected_sha = "325c0f1261e0c61bcae369a1274028e9cfb7ab7949c05512c5b1e630f7e80e12"

# Download URLs
let base_url = $"https://nodejs.org/dist/v($node_version)"
let tarball_url = $"($base_url)/($filename)"

print $"Downloading Node.js v($node_version) for ($arch)..."

# Download the tarball
http get $tarball_url | save -f $filename

# Calculate the SHA256 hash of the downloaded file
let actual_sha = (open $filename --raw | hash sha256)

# Verify the SHA matches
if $actual_sha != $expected_sha {
    print $"SHA256 verification failed!"
    print $"Expected: ($expected_sha)"
    print $"Actual:   ($actual_sha)"
    exit 1
}

print "SHA256 verification passed!"

# Extract the tarball
print "Extracting Node.js..."
^tar -xf $filename

# Move Node.js to /usr/local
let node_dir = $"node-v($node_version)-($arch)"
^mv $node_dir /usr/local/node

# Create symlinks for node, npm, and npx
print "Creating symlinks..."
^ln -sf /usr/local/node/bin/node /usr/local/bin/node
^ln -sf /usr/local/node/bin/npm /usr/local/bin/npm
^ln -sf /usr/local/node/bin/npx /usr/local/bin/npx

# Clean up
rm $filename

print $"Node.js v($node_version) installed successfully!"
print "Verifying installation..."
^node --version
^npm --version
