# rust

Rust code that supports my personal workflows.


## Overview

This directory contains an experimental Rust implementation of `my-fuzzy-finder`, a new `run-from-readme-rs`
prototype, and the matching library they share.

I implemented this with Cursor and cloud agents. The interactive behavior was validated in Cursor Cloud with manual
computer-use sessions and screen/video capture.


### `my-fuzzy-finder/`

An experimental Rust commandline fuzzy finder with a JSON API. The compiled binary is named `my-fuzzy-finder-rs`.


### `my-fuzzy-finder-lib/`

An experimental Rust library containing the fzf-inspired matching logic used by `my-fuzzy-finder`.


### `run-from-readme/`

A Rust TUI prototype for selecting shell snippets from a README and emitting either the escaped Nushell command or the
raw snippet directly.


## Dependency Notes

The Rust implementation depends on a small set of crates on purpose:

- `ratatui` renders the TUI.
- `crossterm` handles terminal mode changes, key input, and screen switching.
- The `crossterm` `use-dev-tty` feature is enabled because this program needs to read candidates from standard input
  while still reading key presses from the terminal device, and that backend matters for compatibility on macOS.
- `serde` with the `derive` feature lets `my-fuzzy-finder` serialize the selected item to JSON with a compact `struct`.
- `serde_json` handles the JSON input/output mode.
- `unicode-width` is needed because item layout and paging should account for display width, not byte length or rune
  count, especially for emoji and other wide characters.

You might notice `libc` in the dependency tree while building. It is not something I call directly in the Rust source
right now, but it is still part of the terminal stack used underneath `crossterm`.


## Instructions

Follow these instructions to build, run and install the Rust code.

1. Activate the Nushell `do` module
   * ```nushell
     do activate
     ```
2. Build and test the code:
   * ```nushell
     do test
     ```
3. Build and run the `my-fuzzy-finder-rs` program with the example data:
   * ```nushell
     do run my-fuzzy-finder --example
     ```
   * Next, try a similar thing but with the JSON API.
   * ```nushell
     ["Hello, world!" "Dear reader,
     Hello.
     Sincerely, writer"] | to json | do run my-fuzzy-finder --json-in --json-out
     ```
   * It will output a JSON object like the following.
   * ```json
     {"index": 1, "value": "Dear reader,\nHello.\nSincerely, writer"}
     ```
4. Build and run the `run-from-readme-rs` prototype:
   * ```nushell
     do run run-from-readme ../mac-os/README.md
     ```
   * Use `Enter` to run the selected snippet with its default mode.
   * Use `Shift+Enter` when your terminal reports that key combination, or `F2` as a fallback, to run a shell snippet
     as-is and remember that choice for future sessions.
5. Build the executables:
   * ```nushell
     do build
     ```
   * The executables will be copied to `bin/my-fuzzy-finder-rs` and `bin/run-from-readme-rs`.
6. Install the executables:
   * ```nushell
     do install
     ```
   * This installs both `my-fuzzy-finder-rs` and `run-from-readme-rs`.
