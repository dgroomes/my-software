#!/usr/bin/env bash
#
# This is a launcher script for launching the "Time" MCP server. This is one of the reference servers of the Model
# Context Protocol project: https://github.com/modelcontextprotocol/servers/tree/main
#
# I'm using uv to launch the server and I'm pinning to a specific version number because this software is pre-1.0 so
# breaking changes are likely.
#
# The special thing I want to do with this launcher is capture a copy of standard input and output. At its simplest, an
# MCP server is just a little bit of JSON sent across stdin and stdout. Simple stuff. Let's see it in action.

# Bash trick to get the directory containing the script. See https://stackoverflow.com/a/246128
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Log to files relative to the script dir.
STDIN_LOG="${DIR}/time-in.jsonl"
STDOUT_LOG="${DIR}/time-out.jsonl"

# Use 'tee' to capture stdin and stdout.
#
# Note: I've found I need to specify '--local-timezone' directly otherwise I get a backtrace complaining about 'CDT' not
# being found.
tee "$STDIN_LOG" | uvx mcp-server-time@0.6.2 --local-timezone=America/Chicago | tee "$STDOUT_LOG"
