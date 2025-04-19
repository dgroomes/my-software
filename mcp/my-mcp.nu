# An MCP server implemented in Nushell.
#
# Well, I can't exactly implement a server directly in Nu because you can't read line by line non-interactively? I've
# tried a lot of combinations and research but can't get it to work. See https://github.com/nushell/nushell/issues/14901
#
# However, we can implement the "handler" part of an MCP server. That's the vast majority of code and functionality
# anyway, so that's good.

# JSON-RPC error codes
const METHOD_NOT_FOUND = -32601

const INIT = {
    protocolVersion: "2024-11-05",
    capabilities: {
        tools: {
            listChanged: true
        }
    },
    serverInfo: {
        name: MyMCPServer,
        version: "0.1.0"
    }
}

const TOOLS = [
    {
        name: "time",
        description: "Get the current time in various formats",
        inputSchema: {
            type: "object",
            properties: {
                format: {
                  type: "string",
                  description: "Format to display the time (defaults to a locale format if omitted)",
                  enum: ["ISO", "UNIX"]
                }
              },
            required: []
        }
    }
]

export def main [] {
    $in | from json | handle | to json --raw
}

def ok [res result] {
    $res | merge { result: $result }
}

def e [res code msg] {
    $res | merge { error: { code: $code message: $msg } }
}

def handle [] {
    let req = $in
    let res = { jsonrpc: "2.0" id: $req.id? }

    match $req.method? {
        "initialize" => { ok $res $INIT }
        "tools/list" => { ok $res { tools: $TOOLS } }
        "tools/call" => {
            let tool = $req.params.name
            let args = $req.params.arguments?
            handle_tool $tool $args $res
        }
        _ => { e $res $METHOD_NOT_FOUND $"Method not supported: ($req.method?)" }
    }
}

def handle_tool [tool args res] {
    match $tool {
        "time" => { execute_time $args $res }
        _ => { e $res $METHOD_NOT_FOUND $"Tool not found: ($tool)" }
    }
}

def execute_time [args res] {
    let fmt = $args.format? | default "ISO"

    let time_value = if $fmt == "ISO" {
        date now | format date "%+"
    } else if $fmt == "UNIX" {
        date now | format date "%s"
    } else {
        date now | format date
    }

    ok $res {
        content: [
            {
                type: "text",
                text: $time_value
            }
        ]
    }
}
