const DIR = (path self | path dirname)

# Generate the `package.json` file.
export def package-json [] {
    cd $DIR

    let mcp_sdk = "~1.10.2" # MCP SDK releases: https://github.com/modelcontextprotocol/typescript-sdk/releases
    let typescript = "~5.8.3" # TypeScript releases: https://github.com/Microsoft/TypeScript/releases

    let packageJson = {
        name: "mcp-context-library",
        version: "0.1.0",
        description: "An MCP server that provides quick access to a local 'context library' of frequently referenced files.",
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

export def test [] {
    cd $DIR
    npm test
}

# Start the server in interactive mode
export def run [] {
    cd $DIR
    node dist/index.js
}

# Start the server with the MCP Inspector
export def run-with-inspector [] {
    cd $DIR
    npx @modelcontextprotocol/inspector@0.9.0 ./context-library.sh
}
