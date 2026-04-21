# nushell-client

**NOTICE**: This code was almost fully implemented with a coding agent.

A small Kotlin/JVM library for talking to Nushell from the JVM.


## Overview

It wraps the few entry points we use to get language information out of Nushell itself:

- The [`rust/nu-lex/`](../../rust/nu-lex/) sidecar (Nushell's official `nu_parser::lex`,
  exposed over a length-prefixed binary stdio protocol). Use [`NuLex`](src/dgroomes/nushell/NuLex.kt).
- `nu --ide-ast` (the canonical token + shape stream `nu` itself uses to color its REPL).
  Returns JSON; we parse it with Jackson. Use [`NuIde.ideAst`](src/dgroomes/nushell/NuIde.kt).
- `nu --ide-check` (inferred-type hints and parse diagnostics). Also JSON.
  Use [`NuIde.ideCheck`](src/dgroomes/nushell/NuIde.kt).
