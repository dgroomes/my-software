const DIR = path self | path dirname

export def test [] {
    cd $DIR

    gw test
}

export def build [] {
    cd $DIR

    gw --quiet installDist
}

export def run-with-inspector [] {
    cd $DIR

    npx @modelcontextprotocol/inspector@0.13.0 ./mcp.sh
}

export def trunc-and-follow [] {
    "" | save -f mcp.in.mcp.jsonl
    "" | save -f mcp.out.mcp.jsonl
    "" | save -f mcp.err.mcp.log

    tail -f mcp.in.mcp.jsonl mcp.out.mcp.jsonl mcp.err.mcp.log
}
