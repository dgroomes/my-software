# Exploring Tart

export def doit [] {
    tart clone ghcr.io/cirruslabs/macos-tahoe-base:latest tahoe-base
}

export def run [] {
    tart run tahoe-base
}

export def ip [] {
    tart ip tahoe-base
}

export def ssh [] {
    ^ssh $"admin@(ip)"
}
