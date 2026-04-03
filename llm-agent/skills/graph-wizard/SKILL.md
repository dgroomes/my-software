---
name: graph-wizard
description: Use when you need to turn a natural-language architecture or topology prompt into maxGraph XML, an mxGraph-compatible XML export, a rendered PNG, a diagram report, and a markdown summary using the `javascript/max-graph-editor` project.
---

# graph-wizard

## Overview

This skill captures the `graph-wizard` workflow implemented in `javascript/max-graph-editor`.

Use it when the task is to:

- draft a diagram from a plain-English prompt
- render the diagram to an image
- inspect the rendered output
- hand back machine-readable artifacts like XML, JSON, and markdown summary

The workflow is Bun-first and Bash-friendly. Do not depend on Nushell.


## When To Use

Use this skill when the user wants something like:

- "make me a graph of ..."
- "generate a max graph / mxGraph diagram from this description"
- "render an architecture diagram from a prompt"
- "iterate on a topology diagram"
- "produce XML and an image for a system diagram"

Do not use this skill if the task is only about manual editing of an existing diagram in the browser UI with no prompt-driven generation.


## Files And Commands

Project root:

- `javascript/max-graph-editor`

Important files:

- `javascript/max-graph-editor/graph-wizard.ts`
- `javascript/max-graph-editor/src/wizard/`
- `javascript/max-graph-editor/src/client/main.tsx`
- `javascript/max-graph-editor/README.md`

Core commands:

1. Install dependencies
   - ```shell
     export PATH="$HOME/.bun/bin:$PATH"
     bun install
     ```
2. Build the browser client
   - ```shell
     export PATH="$HOME/.bun/bin:$PATH"
     bun run build-client
     ```
3. Type-check the project
   - ```shell
     export PATH="$HOME/.bun/bin:$PATH"
     bun run check
     ```
4. Run the wizard
   - ```shell
     export PATH="$HOME/.bun/bin:$PATH"
     bun graph-wizard.ts "please give me a graph of a network topology for how AWS Lambda functions work and please show the logging infrastructure"
     ```


## Expected Outputs

The wizard writes an artifact bundle under:

- `javascript/max-graph-editor/out/<timestamp>-<slug>/`

Expect these files:

- `prompt.txt`
- `diagram-spec.json`
- `diagram.maxgraph.xml`
- `diagram.mxgraph.xml`
- `diagram.png`
- `diagram-report.json`
- `diagram-summary.md`

The CLI also prints a JSON result to stdout describing the output directory, provider used, final spec, render report, summary, and artifact paths.


## Provider Behavior

- If `OPENAI_API_KEY` is set, `graph-wizard` will attempt to use OpenAI for the first draft.
- If no API key is configured, or if the OpenAI call fails, the workflow falls back to a deterministic heuristic drafter.
- The fallback behavior is acceptable and expected in cloud environments where credentials are unavailable.


## Validation Workflow

When using this skill, validate in this order:

1. Run:
   - ```shell
     export PATH="$HOME/.bun/bin:$PATH"
     bun run build-client
     bun run check
     ```
2. Run `graph-wizard.ts` with the user's prompt.
3. Inspect:
   - stdout JSON
   - `diagram-report.json`
   - `diagram-summary.md`
   - `diagram.png`
4. If the change affects UI/rendering, manually validate in the browser:
   - start the server against the generated `diagram.maxgraph.xml`
   - open normal editor mode
   - open render-only mode with `?mode=render`
   - confirm the diagram is legible and the topology is coherent

Recommended manual validation command:

- ```shell
  export PATH="$HOME/.bun/bin:$PATH"
  bun src/server.ts "/absolute/path/to/generated/diagram.maxgraph.xml" 3200
  ```

Then visit:

- `http://127.0.0.1:3200`
- `http://127.0.0.1:3200/?mode=render`


## Output Quality Checklist

Before calling the work done, check:

- nodes referenced by the prompt are present
- edges form a coherent flow rather than isolated boxes
- observability/logging nodes are included when the prompt asks for them
- network/topology prompts do not leave boundary nodes disconnected
- `diagram.png` is diagram-only and free of editor chrome
- `diagram-summary.md` explains the result and suggests useful next refinements


## Notes For Agents

- Prefer Bun commands directly over `do.nu`.
- Preserve the generated bundle in `out/`; it is useful evidence.
- If you improve the workflow itself, update this skill and the project README together.
