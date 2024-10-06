export def install [] {
    cd $env.DO_DIR

    node package-json.mjs
    npm install
}

export def build [] {
    node build.mjs
}

export def run [] {
    node dist/main.bundle.js
}
