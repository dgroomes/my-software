---
name: cursor-cloud-agents
description: Use when you need to inspect, launch, follow up on, stop, or delete Cursor Cloud Agents from a shell or another agent. Covers Cursor CLI installation, Cursor Cloud Agent API usage, and secret handling for the configured `caak` API key.
---

# Cursor Cloud Agents

## Overview

Use this skill when you need to interact with Cursor Cloud Agents programmatically.

In this repository's cloud environment, the configured Cursor secret named `caak` is exposed as the environment variable `caak`. Treat it like an API key and never print its value.

The Cursor CLI is useful to install and keep available, but for cloud-agent lifecycle management the REST API is the most reliable interface. In this environment, `agent about`, `agent status`, and similar subcommands still attempted interactive login even when `--api-key "$caak"` was provided.


## Instructions

Follow these instructions to install the Cursor CLI, verify the secret, and manage Cursor Cloud Agents.

1. Pre-requisites
   * `curl` and `jq` must be installed.
   * The Cursor Cloud secret `caak` must exist in Cursor Cloud settings.
   * Never echo `$caak` directly.
2. Install the Cursor CLI
   * ```shell
     curl https://cursor.com/install -fsS | bash
     export PATH="$HOME/.local/bin:$PATH"
     agent --version
     ```
   * In this environment the command installed `agent` at `~/.local/bin/agent`.
3. Verify that the `caak` secret is available without leaking it
   * ```shell
     if [ -n "${caak+x}" ]; then
       echo "caak is present"
     else
       echo "caak is missing"
     fi
     ```
   * In this environment the secret name matched the environment variable name exactly: `caak`.
4. Verify the API key works
   * ```shell
     curl -sS \
       -H "Authorization: Bearer $caak" \
       -H "Accept: application/json" \
       https://api.cursor.com/v0/me | jq
     ```
   * Expected result: JSON with fields like `apiKeyName`, `createdAt`, and `userEmail`.
5. List available repositories and models
   * ```shell
     curl -sS \
       -H "Authorization: Bearer $caak" \
       -H "Accept: application/json" \
       https://api.cursor.com/v0/repositories | jq

     curl -sS \
       -H "Authorization: Bearer $caak" \
       -H "Accept: application/json" \
       https://api.cursor.com/v0/models | jq
     ```
6. List recent cloud agents
   * ```shell
     curl -sS \
       -H "Authorization: Bearer $caak" \
       -H "Accept: application/json" \
       https://api.cursor.com/v0/agents | jq
     ```
   * To get a smaller report:
   * ```shell
     curl -sS \
       -H "Authorization: Bearer $caak" \
       -H "Accept: application/json" \
       https://api.cursor.com/v0/agents |
       jq -r '.agents[] | [.id, .status, .name, .source.repository, .target.branchName] | @tsv'
     ```
7. Inspect one agent
   * ```shell
     AGENT_ID="bc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

     curl -sS \
       -H "Authorization: Bearer $caak" \
       -H "Accept: application/json" \
       "https://api.cursor.com/v0/agents/$AGENT_ID" | jq

     curl -sS \
       -H "Authorization: Bearer $caak" \
       -H "Accept: application/json" \
       "https://api.cursor.com/v0/agents/$AGENT_ID/conversation" | jq
     ```
8. Launch a new cloud agent
   * ```shell
     jq -n \
       --arg repo "https://github.com/OWNER/REPO" \
       --arg ref "main" \
       --arg branch "cursor/my-task" \
       --arg prompt "Describe the task clearly and precisely." \
       '{
         prompt: { text: $prompt },
         source: { repository: $repo, ref: $ref },
         target: { branchName: $branch, autoCreatePr: false }
       }' > /tmp/cursor-launch.json

     curl -sS \
       -X POST \
       -H "Authorization: Bearer $caak" \
       -H "Content-Type: application/json" \
       -d @/tmp/cursor-launch.json \
       https://api.cursor.com/v0/agents | jq
     ```
   * Important request shape:
     * `prompt` must be an object with a `text` field.
     * `source` must be an object, not an array.
     * `target.branchName` and `target.autoCreatePr` are accepted.
9. Send a follow-up message to a running agent
   * ```shell
     AGENT_ID="bc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

     jq -n \
       --arg prompt "Also update the README and summarize the changes." \
       '{ prompt: { text: $prompt } }' > /tmp/cursor-followup.json

     curl -sS \
       -X POST \
       -H "Authorization: Bearer $caak" \
       -H "Content-Type: application/json" \
       -d @/tmp/cursor-followup.json \
       "https://api.cursor.com/v0/agents/$AGENT_ID/followup" | jq
     ```
10. Stop or delete an agent
   * ```shell
     AGENT_ID="bc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

     curl -sS \
       -X POST \
       -H "Authorization: Bearer $caak" \
       -H "Accept: application/json" \
       "https://api.cursor.com/v0/agents/$AGENT_ID/stop" | jq

     curl -sS \
       -X DELETE \
       -H "Authorization: Bearer $caak" \
       -H "Accept: application/json" \
       "https://api.cursor.com/v0/agents/$AGENT_ID" | jq
     ```
   * Use `stop` to halt work and `DELETE` to remove the agent record.
11. Prefer API calls over the installed CLI for cloud-agent management
   * ```shell
     agent --version
     ```
   * Keep the CLI installed for local/headless agent workflows, shell integration, and future updates.
   * For listing and managing cloud agents, prefer the `https://api.cursor.com/v0/...` endpoints shown above.


## Reference

- Cursor CLI installation: `https://cursor.com/install`
- Cursor Cloud Agents API base URL: `https://api.cursor.com/v0`
- Verified endpoints in this environment:
  - `GET /v0/me`
  - `GET /v0/models`
  - `GET /v0/repositories`
  - `GET /v0/agents`
  - `GET /v0/agents/{id}`
  - `GET /v0/agents/{id}/conversation`
  - `POST /v0/agents`
  - `POST /v0/agents/{id}/followup`
  - `POST /v0/agents/{id}/stop`
  - `DELETE /v0/agents/{id}`
