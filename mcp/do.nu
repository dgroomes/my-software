const DIR = path self | path dirname
const inspector = "@modelcontextprotocol/inspector@0.9.0"

# Launch the MCP Inspector with the "Time" server.
#
# MCP Inspector: https://modelcontextprotocol.io/docs/tools/inspector
export def time [] {
    let launcher = [$DIR time-launcher.sh] | path join
    npx $inspector $launcher
}

export def my-mcp [] {
    let my_mcp = [$DIR my-mcp-launcher.sh] | path join
    npx $inspector $my_mcp
}

# Clear the captured MCP server input/output (.jsonl and .log)
export def clear [] {
    ls *.mcp.jsonl *.mcp.log | each { |f| "" | save -f $f.name }
    return
}
