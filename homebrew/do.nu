use zdu.nu err

const DIR = path self | path dirname

# Get JDK release info so that I can create a new Homebrew formula
export def jdk-info [release] {
    let assets = http get ("https://api.adoptium.net/v3/assets/release_name/eclipse/" + $release + "?architecture=aarch64&image_type=jdk&os=mac&project=jdk")

    let bl = $assets.binaries | length
    if ($bl != 1) {
        err $"Expected the 'binaries' field to have exactly one entry but found ($bl)"
    }

    $assets.binaries.0.package | select link checksum
}
