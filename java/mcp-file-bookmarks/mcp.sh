#!/usr/bin/env bash
# Bash script to launch the File Bookmarks MCP server, capturing copies of stdin/stdout/stderr.

# Get the directory containing the script
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Log to files relative to the script dir
in="${dir}/mcp.in.mcp.jsonl"
out="${dir}/mcp.out.mcp.jsonl"
err="${dir}/mcp.err.mcp.log"

# Set up tee to capture input/output
exec 0< <(tee "$in")
exec 1> >(tee "$out")
exec 2> >(tee "$err" >&2)

# Run the server
exec "${dir}/build/install/mcp-file-bookmarks/bin/mcp-file-bookmarks"
