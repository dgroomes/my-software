# my-obsidian-plugin

My personal Obsidian plugin.


## Overview

Not really sure what I'm going to do with this yet but Obsidian seems like a pretty rich and stable base to build from.
I'm especially interested in search.


## Instructions

1. Pre-requisite: Node.js
   * I'm using `v23.7.0`
2. Activate the Nushell `do` commands
   * ```nushell
     do activate
     ```
3. Install dependencies
   * ```nushell
     do install
     ```
4. Build the plugin distribution
   * ```nushell
     do build
     ```
5. Install the plugin
   * ```nushell
     do install-plugin
     ```

## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [x] DONE Start project by copying the sample plugin.
* [x] DONE pare down esbuild
* [x] DONE Get intellisense to work
* [x] DONE Pare down some of the features to the point I understand most of the plugin code
* [x] DONE Update versions
* [x] DONE `package-json.mjs` or similar
* [ ] Consider Vite (I don't know I'm very happy with esbuild)

## Reference

* [Obsidian API](https://github.com/obsidianmd/obsidian-api)
* [Official sample plugin](https://github.com/obsidianmd/obsidian-sample-plugin)
