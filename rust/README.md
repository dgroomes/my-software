# rust

Rust code that supports my personal workflows.


## Overview

This directory contains an experimental Rust implementation of `my-fuzzy-finder` and its matching library.

I implemented this with Cursor and cloud agents. The interactive behavior was validated in Cursor Cloud with manual
computer-use sessions and screen/video capture.


### `my-fuzzy-finder/`

An experimental Rust commandline fuzzy finder with a JSON API.


### `my-fuzzy-finder-lib/`

An experimental Rust library containing the fzf-inspired matching logic used by `my-fuzzy-finder`.


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
3. Build and run the `my-fuzzy-finder` program with the example data:
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
4. Build the executable:
   * ```nushell
     do build
     ```
   * The executable will be copied to `bin/my-fuzzy-finder`.
5. Install the executable:
   * ```nushell
     do install
     ```
   * This uses `cargo install --path my-fuzzy-finder --force` so it can overwrite an already-installed binary, including
     the Go implementation if that is what is currently on your `PATH`.
