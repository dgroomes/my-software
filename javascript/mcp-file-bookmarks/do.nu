const DIR = (path self | path dirname)

# Generate the `package.json` file.
export def package-json [] {
    cd $DIR

    let mcp_sdk = "~1.10.2" # MCP SDK releases: https://github.com/modelcontextprotocol/typescript-sdk/releases
    let typescript = "~5.8.3" # TypeScript releases: https://github.com/Microsoft/TypeScript/releases

    let packageJson = {
        name: "mcp-file-bookmarks",
        version: "0.1.0",
        description: "An MCP server for quickly referencing bookmarked local files.",
        type: "module",
        main: "dist/index.js",
        scripts: {
            build: "tsc",
            test: "node --test"
        },
        dependencies: {
            "@modelcontextprotocol/sdk": $mcp_sdk
        },
        devDependencies: {
            typescript: $typescript,
            "@types/node": "^22.14.1"
        }
    }

    $packageJson | save --force package.json
}

export def install [] {
    cd $DIR
    npm install
}

export def build [] {
    cd $DIR
    npm run build
}

export def run-with-inspector [] {
    cd $DIR
    npx @modelcontextprotocol/inspector@0.9.0 ./file-bookmarks.sh
}
