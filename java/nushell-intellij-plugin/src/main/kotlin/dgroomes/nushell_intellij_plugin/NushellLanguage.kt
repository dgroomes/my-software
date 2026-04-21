package dgroomes.nushell_intellij_plugin

import com.intellij.lang.Language

/**
 * The Nushell [Language] singleton. Registering this with IntelliJ unlocks the rest of the
 * Custom Language Support APIs (PSI, Structure View, formatter, references, etc.).
 *
 * This plugin maintains no Nushell parser, lexer, or grammar of its own. Three pipelines, all
 * delegating to Nushell:
 *
 *   - **Lexer / structural highlighting**: `nu_parser::lex`, exposed by the `nu-lex` Rust
 *     sidecar (see `rust/nu-lex/`). Powers token boundaries, brace matching, comment toggling.
 *   - **Semantic highlighting and Structure View**: `nu --ide-ast`. Drives the per-token
 *     shape colors (variable, keyword, internal call, flag, number, string, type, …) and
 *     populates the IntelliJ Structure tool window.
 *   - **Hover, completion, go-to-definition, find usages, diagnostics**: `nu --lsp`.
 */
object NushellLanguage : Language("Nushell")
