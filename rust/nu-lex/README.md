# nu-lex

A long-lived sidecar process that wraps Nushell's official `nu_parser::lex` and serves
tokens over a length-prefixed binary stdio protocol.


## Overview

The motivation is the IntelliJ Nushell plugin in [`java/nushell-intellij-plugin/`](../../java/nushell-intellij-plugin/),
which needs an IntelliJ-side lexer that perfectly matches `nu` itself. Rather than re-implement
Nushell's lexer in Kotlin (and re-introduce drift bugs every time the upstream lexer changes),
the plugin spawns this binary and pipes lex requests through it. Other JVM clients are welcome
too — there is nothing IntelliJ-specific in this crate or its protocol.

The crate depends on `nu-parser` and `nu-protocol` from `crates.io` as regular cargo
dependencies, pinned to a specific `nu` version. Bumping is a one-line change to `Cargo.toml`.


## Stdio protocol

All multi-byte integers are little-endian.

```
request:  u32 byte length, followed by exactly that many UTF-8 bytes
reply:    u32 token count, followed by `count` token records
token:    u8 kind, u32 byte start, u32 byte end
```

Offsets are byte offsets into the request buffer (which is what `nu_parser::lex` returns).
Translating to character offsets is the caller's responsibility.

The `kind` byte tags are listed at the top of `src/main.rs`. Do not renumber existing
entries; clients read them as raw `u8` values.

The sidecar also sub-emits an `Item` whose first byte signals structure as separate
bracket-open / inner / bracket-close tokens (or a single quoted-string token), so callers
that need to wire up brace-matching or string-literal services don't have to re-lex inside
the `Item`. That decision lives here, beside the upstream `lex` call, instead of in the
client. See the comment at the top of `src/main.rs`.


## Build

```nushell
cargo build --release
```

Output binary: `target/release/nu-lex`.
