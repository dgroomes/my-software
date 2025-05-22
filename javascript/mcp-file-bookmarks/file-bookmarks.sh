#!/usr/bin/env bash
# Bash script to launch the File Bookmarks MCP server, capturing copies of stdin/stdout/stderr.

# Get the directory containing the script
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Log to files relative to the script dir
in="${dir}/file-bookmarks.in.mcp.jsonl"
out="${dir}/file-bookmarks.out.mcp.jsonl"
err="${dir}/file-bookmarks.err.mcp.log"

# Set up tee to capture input/output
exec 0< <(tee "$in")
exec 1> >(tee "$out")
exec 2> >(tee "$err" >&2)

# Run the server
exec node "${dir}/dist/index.js"
