const DIR = path self | path dirname

# Generate the `package.json` file.
export def package-json [] {
    cd $DIR

    let mcp_sdk = "1.30.0" # MCP SDK releases: https://github.com/modelcontextprotocol/typescript-sdk/releases
    let typescript = "7.0.2" # TypeScript releases: https://github.com/microsoft/typescript-go/releases
    let types_node = "26.1.2"

    let packageJson = {
        name: "mcp-rules",
        version: "0.1.0",
        description: "An MCP server for bootstrapping LLM agents with user- and project-specific rules.",
        type: "module",
        main: "dist/index.js",
        dependencies: {
            "@modelcontextprotocol/sdk": $mcp_sdk
        },
        devDependencies: {
            typescript: $typescript,
            "@types/node": $types_node
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
    npx tsc
}

export def run-with-inspector [] {
    cd $DIR

    # MCP Inspector releases: https://www.npmjs.com/package/@modelcontextprotocol/inspector
    npx @modelcontextprotocol/inspector@0.22.0 ./rules.sh
}

export def install-server [] {
    cd $DIR
    let cmd = "rules.sh" | path expand
    claude mcp add --scope user rules $cmd
}

export def trunc-and-follow [] {
    "" | save -f rules.in.mcp.jsonl
    "" | save -f rules.out.mcp.jsonl
    "" | save -f rules.err.mcp.log

    tail -f rules.in.mcp.jsonl rules.out.mcp.jsonl rules.err.mcp.log
}

