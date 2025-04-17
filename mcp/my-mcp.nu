#!/opt/homebrew/bin/nu --stdin
#
# Can I implement an MCP server in Nu? WORK IN PROGRESS

const DIR = path self | path dirname

export def main [] {
    let in_f = [$DIR my-mcp-in.jsonl] | path join
    let out_f = [$DIR my-mcp-out.jsonl] | path join

    loop {
        let i = input
        $i | save -a $in_f
        let o = $i | from json | handle
        $o | to json | save -a $out_f
    }
}

def handle [] {
    let m = $in.method?
    print -e $"handle for ($m)"
    if ($m == "initialize") {
        return initialize
    } else {
        return {
            jsonrpc: "2.0"
            id: $in.id?
            error: $"Method not supported ($m)"
        }
    }
}

def initialize [] {
  {
    jsonrpc: "2.0",
    id: 0,
    result: {
      protocolVersion: "2024-11-05",
      capabilities: {
        tools: {
          listChanged: true
        }
      },
      serverInfo: {
        name: "MyMCPServer",
        version: "0.1.0"
      }
    }
  }
}
