const DIR = path self | path dirname
const inspector = "@modelcontextprotocol/inspector@0.9.0"

# Launch the MCP Inspector with the "Time" server.
#
# MCP Inspector: https://modelcontextprotocol.io/docs/tools/inspector
export def time-server [] {
    let launcher = [$DIR time-launcher.sh] | path join
    npx $inspector $launcher
}

# I can't get this to work. Keeping it here in case I can figure it out.
export def time-server-nu [] {
    let launcher = [$DIR time-launcher.nu] | path join
    npx $inspector $launcher
}

export def my-mcp-server [] {
    let my_mcp = [$DIR my-mcp.nu] | path join
    npx $inspector $my_mcp
}
