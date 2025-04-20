const DIR = path self | path dirname
const inspector = "@modelcontextprotocol/inspector@0.9.0"

# Launch the MCP Inspector with the "Time" server.
#
# MCP Inspector: https://modelcontextprotocol.io/docs/tools/inspector
export def launch [] {
    let launcher = [$DIR time.sh] | path join
    npx $inspector $launcher
}

export def clear [] {
    ls *.mcp.jsonl *.mcp.log | each { |f| "" | save -f $f.name }
    return
}
