# Can I implement an MCP server in Nu?
#
# No, I can't exactly implement a server directly in Nu because you can't read line by line non-interactively? I've
# tried a lot of combinations and research but can't get it to work. See https://github.com/nushell/nushell/issues/14901
#
# However, we can implement the "handler" part of an MCP server. That's the vast majority of code and functionality
# anyway, so that's good.

const DIR = path self | path dirname

# JSON-RPC error codes
const ERROR_PARSE_ERROR = -32700
const ERROR_INVALID_REQUEST = -32600
const ERROR_METHOD_NOT_FOUND = -32601
const ERROR_INVALID_PARAMS = -32602

const PROTOCOL_VERSION = "2024-11-05"

const SERVER_NAME = "MyMCPServer"
const SERVER_VERSION = "0.1.0"

export def main [] {
    $in | from json | handle | to json --raw
}

def handle [] {
    let msg = $in
    let m = $msg.method?
    let id = $msg.id?
    if ($m == null) {
        return {
            jsonrpc: "2.0"
            id: $id
            error: {
                code: $ERROR_INVALID_REQUEST
                message: "Invalid Request: missing method"
            }
        }
    }

    if ($m == "initialize") {
        return (initialize $id)
    } else if ($m == "tools/list") {
        return (list_tools $id)
    } else if ($m == "tools/call") {
        let tool_name = $msg.params?.name?
        let tool_args = $msg.params?.arguments?

        if ($tool_name == null) {
            return {
                jsonrpc: "2.0"
                id: $id
                error: {
                    code: $ERROR_INVALID_PARAMS
                    message: "Missing tool name parameter"
                }
            }
        }

        return (execute_tool $id $tool_name $tool_args)
    } else {
        return {
            jsonrpc: "2.0"
            id: $id
            error: {
                code: $ERROR_METHOD_NOT_FOUND
                message: $"Method not supported: ($m)"
            }
        }
    }
}

def initialize [id] {
  {
    jsonrpc: "2.0",
    id: $id,
    result: {
      protocolVersion: $PROTOCOL_VERSION,
      capabilities: {
        tools: {
          listChanged: true
        }
      },
      serverInfo: {
        name: $SERVER_NAME,
        version: $SERVER_VERSION
      }
    }
  }
}

def list_tools [id] {
  {
    jsonrpc: "2.0",
    id: $id,
    result: {
      tools: [
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
    }
  }
}

def execute_tool [id, toolName, args] {
  if ($toolName == "time") {
    return (execute_time $id $args)
  } else {
    return {
      jsonrpc: "2.0",
      id: $id,
      error: {
        code: $ERROR_METHOD_NOT_FOUND,
        message: $"Tool not found: ($toolName)"
      }
    }
  }
}

def execute_time [id, args] {
  let fmt = $args.format? | default "ISO"

  let time_value = if $fmt == "ISO" {
    date now | format date "%+"
  } else if $fmt == "UNIX" {
    date now | format date "%s"
  } else {
    date now | format date
  }

  return {
    jsonrpc: "2.0",
    id: $id,
    result: {
      content: [
        {
          type: "text",
          text: $time_value
        }
      ]
    }
  }
}
