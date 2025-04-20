#!/usr/bin/env bash
# Bash trick to get the directory containing the script. See https://stackoverflow.com/a/246128
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

in="${dir}/in.mcp.jsonl"
out="${dir}/out.mcp.jsonl"
err="${dir}/err.mcp.log"

script="${dir}/hello-world.nu"

while IFS= read -r line; do
  echo "$line" >> "$in"
  # Use 'tee' and redirection to capture stdout and stderr into files without losing them in the pipe.
  echo "$line" | /opt/homebrew/bin/nu --stdin "$script" 2> >(tee -a "$err" >&2) | tee -a "$out"
done
