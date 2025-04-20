const DIR = path self | path dirname
const inspector = "@modelcontextprotocol/inspector@0.9.0"

export def launch [] {
    let launcher = [$DIR wish-list.sh] | path join
    npx $inspector $launcher
}

export def clear [] {
    ls *.mcp.jsonl *.mcp.log | each { |f| "" | save -f $f.name }
    return
}
