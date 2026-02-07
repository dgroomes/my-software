# max-graph-editor

**AI First Draft**: Much of the `max-graph-editor` project was AI-generated. Treat this as a first draft until I prune dead ends and fill in missing pieces.

A minimal [maxGraph][max-graph] editor with live disk sync.


## Overview

I like Mermaid diagrams but I need some architecture diagrams which tend to include more boxes and arrows, and the procedural layout is not good for that, the diagrams become squished and odd. Turns our maxGraph exists, which I didn't realize is a well-maintained fork and descendent of Draw.IO's mxGraph. Very neat.


## Instructions

Follow these instructions to build and run the editor.

1. Activate the Nushell `do` module
   - ```nushell
     do activate
     ```
2. Generate the `package.json` file (if needed)
   - ```nushell
     do package-json
     ```
3. Install dependencies
   - ```nushell
     do install
     ```
4. Build the browser client bundle
   - ```nushell
     do build-client
     ```
5. Type-check the TypeScript client code
   - ```nushell
     do check
     ```
6. Start the editor server with the example diagram file
   - ```nushell
     do server-start data/example-diagram.xml
     ```
7. Confirm server status
   - ```nushell
     do server-status
     ```
8. Start a Puppeteer-managed browser instance (headful)
    - ```nushell
      do browser-start --mode headful --url http://127.0.0.1:3000
      ```
9. Confirm browser status
    - ```nushell
      do browser-status
      ```
10. Capture a screenshot via Puppeteer
    - ```nushell
      do screenshot
      ```
11. Dynamically inject JavaScript in the page (example: add a box)
    - ```nushell
      do browser-eval --js '({label,x,y,width,height}) => { const api = window.__maxGraphEditor; if (!api) return "missing api"; return api.insertVertex(label, x, y, width, height); }' --args-json '{"label":"New Box","x":220,"y":360,"width":140,"height":60}'
      ```
12. Optional: inject JavaScript as a screenshot pre-step (single command)
    - ```nushell
      do screenshot --pre-js '({label,x,y}) => { const api = window.__maxGraphEditor; if (!api) return null; return api.insertVertex(label, x, y, 140, 60); }' --pre-args-json '{"label":"PreShot Box","x":420,"y":460}'
      ```
13. Capture another screenshot after dynamic actions
    - ```nushell
      do screenshot
      ```
14. Print the newest screenshot path
    - ```nushell
      do screenshot-latest
      ```
15. Optional: explicit URL/output path
    - ```nushell
      do screenshot --url http://127.0.0.1:3000 --out .my/screenshots/manual.png
      ```
16. Export a maxGraph XML file to mxGraph-compatible XML
    - ```nushell
      do export-mxgraph data/example-diagram.xml
      ```
17. Stop both server and browser when done
    - ```nushell
      do stop
      ```

The key point is that interaction logic is dynamic:

- Use `do browser-eval --js '...'` or `--js-file ...` for browser-side logic.
- Use `--args-json ...` to parameterize injected JavaScript (no hardcoded operation flags needed).
- Use `do screenshot --pre-js ...` when you want “mutate page then capture” in one command.


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

- [x] DONE Instructions and scripting for running in isolated chrome and for LLM to take screenshot and see it
- [x] DONE Ability to add components
- [x] DONE Ability to delete components
- [x] DONE Add a minimal maxGraph-to-mxGraph compatibility pass for draw.io workflows (for example, compatibility renames in XML where feasible).
- [ ] Add a headless diagram-to-image rendering path (for LLM agentic coding loops where image context is useful).
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
