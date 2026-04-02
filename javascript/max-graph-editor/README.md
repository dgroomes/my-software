# max-graph-editor

**AI First Draft**: Much of the `max-graph-editor` project was AI-generated. Treat this as a first draft until I prune dead ends and fill in missing pieces.

A minimal [maxGraph][max-graph] editor with live disk sync, plus a `graph-wizard` CLI that drafts and renders diagrams from natural-language prompts.


## Overview

I like Mermaid diagrams but I need some architecture diagrams which tend to include more boxes and arrows, and the procedural layout is not good for that, the diagrams become squished and odd. Turns our maxGraph exists, which I didn't realize is a well-maintained fork and descendent of Draw.IO's mxGraph. Very neat.


## Instructions

Follow these instructions to build and run the editor or the `graph-wizard` CLI.

### Bun / Bash workflow

1. Install dependencies
   - `bun install`
2. Build the browser client bundle
   - `bun run build-client`
3. Type-check the project
   - `bun run check`
4. Start the editor server with the example diagram file
   - `bun do.ts server-start --diagram data/example-diagram.xml`
5. Start a Puppeteer-managed browser instance (headful)
   - `bun do.ts browser-start --mode headful --url http://127.0.0.1:3000`
6. Capture a screenshot
   - `bun do.ts screenshot`
7. Stop the browser and server
   - `bun do.ts stop`

### `graph-wizard` workflow

Run the wizard with a natural-language prompt.

- `bun graph-wizard.ts "please give me a graph of a network topology for how AWS Lambda functions work and please show the logging infrastructure"`

By default, the wizard:

- drafts a structured diagram spec from the prompt
- generates maxGraph XML
- exports mxGraph-compatible XML
- renders a diagram-only PNG in a headless browser
- inspects the rendered diagram and applies a small revision pass
- writes a final summary plus suggested changes

The artifact bundle is written under `out/<timestamp>-<slug>/`:

- `prompt.txt`
- `diagram-spec.json`
- `diagram.maxgraph.xml`
- `diagram.mxgraph.xml`
- `diagram.png`
- `diagram-report.json`
- `diagram-summary.md`

The wizard uses OpenAI automatically when `OPENAI_API_KEY` is set. Otherwise it falls back to a deterministic heuristic drafter so the command still works offline.

### Nushell compatibility

If you still want the old helper module, the `do.nu` wrappers remain available:

- `do install`
- `do build-client`
- `do check`
- `do graph-wizard "describe the graph"`

The key point is that interaction logic is dynamic:

- Use `bun do.ts browser-eval --js '...'` or `--js-file ...` for browser-side logic.
- Use `--args-json ...` to parameterize injected JavaScript.
- Use `bun do.ts screenshot --pre-js ...` when you want “mutate page then capture” in one command.


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

- [x] DONE Instructions and scripting for running in isolated chrome and for LLM to take screenshot and see it
- [x] DONE Ability to add components
- [x] DONE Ability to delete components
- [x] DONE Add a minimal maxGraph-to-mxGraph compatibility pass for draw.io workflows (for example, compatibility renames in XML where feasible).
- [x] DONE Add a headless diagram-to-image rendering path (for LLM agentic coding loops where image context is useful).
- [ ] Iterate on the `graph-wizard` prompting loop so rendered-image critique can feed richer revisions.
- [ ] Consider wiring the server to be launched with `my-node-launcher`.
- [ ] Use Bun instead of npm across my JavaScript projects.


## Reference

- [maxGraph][max-graph]
- [Chrome remote debugging docs][chrome-remote-debugging]
- [maxGraph Node example (`js-example-nodejs`)][maxgraph-node-example]
- [Puppeteer][puppeteer]

[max-graph]: https://github.com/maxGraph/maxGraph
[chrome-remote-debugging]: https://developer.chrome.com/docs/devtools/remote-debugging/
[maxgraph-node-example]: https://github.com/maxGraph/maxGraph/tree/main/packages/js-example-nodejs
[puppeteer]: https://pptr.dev/
