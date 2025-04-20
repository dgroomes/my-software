# NOT YET IMPLEMENTED
#
# An MCP server to interact with "Wish List" sections in READMEs.

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
        name: WishListTodoListServer,
        version: "0.1.0"
    }
}

const TOOLS = [
    {
        name: "engage",
        description: "Use this tool to start an engagement with tooling in the 'Wish List' MCP server. You must always start with the 'engage' tool before using other tools in this server. Starting here teaches you essential concepts and instructions.",
        inputSchema: {
            type: "object"
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
        "engage" => { execute_engage $res }
        _ => { e $res $METHOD_NOT_FOUND $"Tool not found: ($tool)" }
    }
}

def execute_engage [res] {
    ok $res {
        content: [
            {
                type: "text",
                text: r#'
The 'Wish List' MCP server provides tooling to interact with 'Wish List' sections in README files. I use the word
'Wish List' as my version of TODO, just out of preference. A wish list (WL) is a bulleted list of items. It is not
rigidly structured because its Markdown, but there is a convention structure to it. Items that have not been completed
have a leading `[ ]` unchecked box. Items that are completed have a checked `[x]` box. Additionally, completed items
have the word DONE after the checkbox. In progress items have the word IN PROGRESS. And there are various other
infrequent descriptors like HOLD, ABANDONED, or SKIPPED. There are no hard rules, but there are conventions. The tools
in this MCP help in locating WL sections in a project, describing WL items, and editing the status of WL items.
'#
            }
        ]
    }
}
