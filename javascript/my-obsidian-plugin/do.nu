const DIR = (path self | path dirname)

# Generate the `package.json` file.
export def package-json [] {
    cd $DIR
    let esbuild = "^0.25.0" # https://github.com/evanw/esbuild/blob/main/CHANGELOG.md

    # Occasionally check which version of Node.js is used by Obsidian by calling `process.versions` in the
    # developer console.
    let nodeTypes = "^20.14.8" # https://www.npmjs.com/package/@types/node?activeTab=versions
    let obsidian = "^1.7.2" # https://www.npmjs.com/package/obsidian?activeTab=versions
    let tslib = "^2.8.1" # https://github.com/microsoft/tslib/releases
    let typescript = "^5.7.3" # https://github.com/Microsoft/TypeScript/releases

    let packageJson = {
        main: "main.js"
        devDependencies: {
            "@types/node": $nodeTypes
            "esbuild": $esbuild
            "obsidian": $obsidian
            "tslib": $tslib
            "typescript": $typescript
        }
    }
    $packageJson | save -f package.json
}

# npm install
export def install [] {
    cd $DIR
    npm install
}

export def clean [] {
    cd $DIR
    rm -rf dist
}

export def build [] {
    cd $DIR
    node build.mjs
}

# Install the plugin into an Obsidian vault.
export def install-plugin [] {
    cd $DIR
    let plugin_dir = "~/vaults/repos-personal/.obsidian/plugins/my-obsidian-plugin" | path expand
    mkdir $plugin_dir
    cp dist/main.js manifest.json $plugin_dir
}
