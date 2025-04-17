#!/opt/homebrew/bin/nu --stdin
#
# This is a launcher script for launching the "Time" MCP server. This is one of the reference servers of the Model
# Context Protocol project: https://github.com/modelcontextprotocol/servers/tree/main
#
# I'm using uv to launch the server and I'm pinning to a specific version number because this software is pre-1.0 so
# breaking changes are likely.
#
# The special thing I want to do with this launcher is capture a copy of standard input and output. At its simplest, an
# MCP server is just a little bit of JSON sent across stdin and stdout. Simple stuff. Let's see it in action.

const DIR = path self | path dirname

export def main [] {
    let in_f = [$DIR in.jsonl] | path join
    let out_f = [$DIR in.jsonl] | path join

    # Note: I've found I need to specify '--local-timezone' directly otherwise I get a backtrace complaining about 'CDT' not
    # being found.
    #
    # I can't get this to work. I tried adding 'lines' but that didn't help. I'm not really sure what to do. It's like
    # buffering the input indefinitely? Can I use configure to Nushell or Nushell's tee to not buffer? always flush?
    $in | tee { save -f $in_f } | uvx mcp-server-time@0.6.2 --local-timezone=America/Chicago | tee { save -f $out_f }
}
