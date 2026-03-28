# rust

Rust code that supports my personal workflows.


## Overview

This directory currently contains a ratatui rewrite of `my-fuzzy-finder`, the interactive fuzzy finder that powers my
Nushell `fz` command.


### `my-fuzzy-finder/`

A Rust commandline fuzzy finder with a JSON API.


## Instructions

Follow these instructions to build and run the Rust code in this directory.

1. Run the tests
   * ```shell
     cargo test --manifest-path rust/my-fuzzy-finder/Cargo.toml
     ```
2. Run the fuzzy finder with example data
   * ```shell
     cargo run --manifest-path rust/my-fuzzy-finder/Cargo.toml -- --example
     ```
