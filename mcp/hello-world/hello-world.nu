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
        name: HelloWorld,
        version: "0.1.0"
    }
}

const TOOLS = [
    {
        name: "greet",
        description: "Give a friendly greeting",
        inputSchema: {
            type: "object",
            properties: {
                subject: {
                  type: "string",
                  description: "The name of the subject/person to greet. For example, 'Oscar' or 'neighbor'."
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
        "greet" => { execute_greet $args $res }
        _ => { e $res $METHOD_NOT_FOUND $"Tool not found: ($tool)" }
    }
}

def execute_greet [args res] {
    let subject = $args.subject? | default "world"
    let greeting = $"Hello, ($subject)!"

    ok $res {
        content: [
            {
                type: "text",
                text: $greeting
            }
        ]
    }
}
