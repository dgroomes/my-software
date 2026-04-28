# nushell-intellij-plugin

**NOTICE**: This code was almost fully implemented with a coding agent.

A first-class IntelliJ language plugin for Nushell.


## Overview

This plugin delegates every semantic decision back to Nushell's own tooling — `nu_parser::lex` for tokenization, `nu --ide-ast` for the canonical shape stream and structure outline, and `nu --lsp` for hover, completion, go-to-definition, find usages, and diagnostics.

This plugin registers Nushell as a real IntelliJ language with its own
[`Language`](src/main/kotlin/dgroomes/nushell_intellij_plugin/NushellLanguage.kt),
[`FileType`](src/main/kotlin/dgroomes/nushell_intellij_plugin/NushellFileType.kt), lexer, parser, and PSI —
the bare minimum so that the rest of the IntelliJ Custom Language Support APIs work — and then
delegates everything semantic to Nushell itself.

| Feature                                                        | Backed by                                                       | Code                                                                             |
|----------------------------------------------------------------|-----------------------------------------------------------------|----------------------------------------------------------------------------------|
| Custom file type, parser, brace matcher, commenter             | Hand-written (very thin)                                        | `NushellParser.kt`, `NushellEditorIntegration.kt`                                |
| **Lexer** (every token boundary)                               | The official `nu_parser::lex` running in a sidecar Rust process | `NushellNativeLexer.kt` + [`rust/nu-lex/`](../../rust/nu-lex/) |
| Lexer-driven highlighting (comments, strings, brackets, pipes) | Same official lexer                                             | `NushellSyntaxHighlighter.kt`                                                    |
| **Semantic highlighting** (every Nushell shape)                | `nu --ide-ast`                                                  | `NushellSemanticAnnotator.kt`                                                    |
| **Structure View** (top-level declarations)                    | `nu --ide-ast`                                                  | `NushellStructureView.kt`                                                        |
| AST cache shared between the annotator and structure view      | —                                                               | `NushellAstCache.kt`                                                             |
| Hover, completion, go-to-definition, find usages, diagnostics  | `nu --lsp`                                                      | `NushellLspServerSupportProvider.kt`                                             |
| Color Scheme settings page (one attribute per Nushell shape)   | —                                                               | `NushellColorSettingsPage.kt`, `colorSchemes/Nushell*.xml`                       |


## Architecture

The non-trivial design choice is that we never try to *re-implement* any Nushell parsing or
lexing inside the plugin. There are exactly four ways the plugin learns about the meaning of
a `.nu` file, and **all four are pinned to upstream Nushell**:

1. **`nu_parser::lex`** is the IntelliJ lexer. The actual lexing happens in a separate
   sidecar Rust process — see [`rust/nu-lex/`](../../rust/nu-lex/) — that
   depends on `nu-parser` from `crates.io` and exposes its `lex()` function over a
   length-prefixed stdin/stdout protocol. [`NushellNativeLexer`](src/main/kotlin/dgroomes/nushell_intellij_plugin/NushellNativeLexer.kt)
   on the Kotlin side spawns one helper process per IDE session, sends each request as
   `[length:u32][bytes...]`, and reads back `[count:u32][token{kind:u8, start:u32, end:u32}...]`.
   The cost per call is a few dozen microseconds.
2. **`nu --ide-ast`** is invoked off-EDT by [`NushellSemanticAnnotator`](src/main/kotlin/dgroomes/nushell_intellij_plugin/NushellSemanticAnnotator.kt)
   (an [`ExternalAnnotator`](https://plugins.jetbrains.com/docs/intellij/annotator.html)) every
   time the daemon re-analyzes the file. The annotator paints each `(span, shape)` tuple onto
   the editor and **stashes the parsed entries** in [`NushellAstCache`](src/main/kotlin/dgroomes/nushell_intellij_plugin/NushellAstCache.kt),
   keyed by document modification stamp.
3. **The cache** is read by [`NushellStructureView`](src/main/kotlin/dgroomes/nushell_intellij_plugin/NushellStructureView.kt)
   to build the outline. The structure view *cannot* shell out to `nu` itself because
   `getChildren()` runs inside a read action and `OSProcessHandler` refuses to block in that
   context.
4. **`nu --lsp`** is started by [`NushellLspServerSupportProvider`](src/main/kotlin/dgroomes/nushell_intellij_plugin/NushellLspServerSupportProvider.kt)
   for opened `.nu` files. Hover, completion, go-to-definition, find usages, and diagnostics all
   ride this LSP channel.


### Decoupled polyglot builds

The Rust sidecar and the JVM plugin are **two separate projects** with two separate build
tools, and Gradle never invokes `cargo`. Per the project-wide convention, polyglot
orchestration belongs in Nushell, not in any individual language's build tool.

What this plugin's Gradle build *does* do: before packaging, it asserts that the prebuilt
sidecar binary exists at `../../rust/nu-lex/target/release/nu-lex`. If
not, it stops with a descriptive error message pointing the user at the `cargo build` step
they missed.


## Requirements

- A **commercial** JetBrains IDE (IntelliJ IDEA Ultimate, WebStorm, PhpStorm, …) — the LSP API
  isn't shipped in IntelliJ Community.
- Build target: 2026.1+.
- The `nu` executable on your `PATH` (used at runtime for `--ide-ast` / `--lsp`).
- The sidecar binary built and present at `rust/nu-lex/target/release/nu-lex`
  (see [the sidecar README](../../rust/nu-lex/README.md) for the one-line build
  command).


## Build & install

```nushell
../gradlew :nushell-intellij-plugin:buildPlugin
```

Plugin ZIP: `java/nushell-intellij-plugin/build/distributions/nushell-intellij-plugin.zip`.
Install with `Settings → Plugins → ⚙ → Install plugin from disk…`.

To try the plugin in a sandboxed IDE:

```nushell
../gradlew :nushell-intellij-plugin:runIde
```

Open any `.nu` file. The semantic colors should appear after the daemon's first analysis pass
(typically within a second). Open the Structure View with `Alt+7` to see top-level declarations.
