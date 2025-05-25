#!/usr/bin/env bash
# Bash script to launch the Rules MCP server, capturing copies of stdin/stdout/stderr.

# Get the directory containing the script
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Log to files relative to the script dir
in="${dir}/rules.in.mcp.jsonl"
out="${dir}/rules.out.mcp.jsonl"
err="${dir}/rules.err.mcp.log"

# Set up tee to capture input/output
exec 0< <(tee "$in")
exec 1> >(tee "$out")
exec 2> >(tee "$err" >&2)

# Run the server
exec node "${dir}/dist/index.js"