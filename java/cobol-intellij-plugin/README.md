# cobol-intellij-plugin

**WARNING**: Unedited AI output

Lean IntelliJ COBOL language support via the Eclipse che4z LSP server.


## Overview

This is a personal, locally-built plugin that gets useful COBOL support into IntelliJ with as
little plugin code as possible. It starts the official
[Eclipse che4z](https://github.com/eclipse-che4z/che-che4z-lsp-for-cobol) language server as an
external process and registers che4z's own TextMate grammar for syntax coloring.

The process boundary is the design: IntelliJ owns the editor integration, while che4z owns COBOL
analysis and the grammar used for coloring. The plugin does not fork che4z, reimplement COBOL
semantics, or embed `server.jar` in-process. Its Gradle build downloads the official release VSIX
and packages `server.jar` plus the TextMate grammar into the locally-built plugin.

| Feature                                                    | Backed by                                                                                                           |
|------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| File type (`.cbl`, `.cob`, `.cobol`, `.cpy`, `.copy`)      | Thin IntelliJ Language + `EmptyLexer` PSI (no COBOL grammar)                                                        |
| Syntax coloring                                            | che4z TextMate grammar, via a COBOL FileType that delegates to TextMate (extension lookup + TextMate token storage) |
| Hover, completion, navigation, diagnostics, Structure View | che4z `server.jar` over LSP (stdio); Structure View via the platform's LSP document-symbol support                  |

che4z is not plain LSP: the server calls custom client methods (notably `availableDialects`)
and expects language id `cobol` plus several `cobol-lsp.*` workspace settings. The plugin supplies
only the client stubs and defaults needed for base COBOL analysis.


## Instructions

Follow these instructions to build and install the plugin on a fresh Mac:

1. Install IntelliJ IDEA 2026.2 or newer and a Java 21 JDK.
2. From this repository's `java/` directory, build the plugin:
   ```nushell
   ../gradlew :cobol-intellij-plugin:buildPlugin
   ```
3. Find the plugin ZIP at
   `cobol-intellij-plugin/build/distributions/cobol-intellij-plugin.zip`.
4. In IntelliJ, open `Settings → Plugins`, select the gear menu, choose
   `Install Plugin from Disk…`, select the ZIP, and restart IntelliJ when prompted.
5. Open a `.cbl`, `.cob`, `.cobol`, `.cpy`, or `.copy` file. Syntax coloring should appear
   immediately; the status bar LSP widget should show COBOL.

The first build needs network access to download the pinned che4z VSIX. No separate che4z
installation is needed. The bundled IntelliJ TextMate plugin must be enabled (it is by default). After
installing a new ZIP, restart IntelliJ so the COBOL FileType and TextMate bundle
are both picked up — an old install can leave `.cob` as COBOL for Structure View
while the editor stays uncolored.

To try the plugin in a sandbox IDE instead:

```nushell
../gradlew :cobol-intellij-plugin:runIde
```

The sandbox opens the `sample/` project:

- `HELLO.cbl`: valid file; coloring and LSP smoke test
- `BROKEN.cbl`: expects `Variable WS-UNDEFINED-VAR is not defined`
- `STRUCTURE.cbl`: program / data / procedure hierarchy for Structure View (LSP document symbols)
- `WITH-COPY.cbl` + `copybooks/CUSTOMER.cpy`: local copybook resolution (`COPY CUSTOMER`)
- `hello.cob`: program from [cobol-playground](https://github.com/dgroomes/cobol-playground) (`.cob` coloring)


## che4z integration

The plugin pins che4z 2.5.1. GitHub Releases publish a VSIX rather than a standalone JAR; the
build extracts `server.jar` and the TextMate grammar into the plugin distribution:

```
cobol-intellij-plugin/
├── lib/cobol-intellij-plugin.jar
└── che4z/
    ├── server.jar
    └── textmate/
        ├── package.json              # slim VS Code manifest IntelliJ's TextMate reader accepts
        └── syntaxes/
            └── COBOL.tmLanguage.json # official che4z grammar
```

The distribution is fully assembled at build time. The TextMate `package.json` is a slim
wrapper (language + grammar entries only): IntelliJ's VS Code bundle reader rejects unknown
keys such as che4z's `injectTo`, and che4z's `lang-config.json` lacks the `comments` object
IntelliJ requires, so we don't ship the full extension manifest or language configuration.
The grammar file itself is untouched upstream content. At runtime the plugin resolves these
paths from its own installation directory and launches the server with:

```shell
java -Dline.separator=$'\r\n' -Xmx768M -jar server.jar pipeEnabled
```

The small amount of custom protocol glue is required:

- `textDocument/didOpen` uses language id `cobol`.
- `availableDialects` returns an empty list for base COBOL.
- `workspace/configuration` returns minimal `cobol-lsp.*` defaults. In particular,
  `cobol-lsp.target-sql-backend` must be the valid enum value `NONE`; a missing or empty value
  aborts analysis. Copybook settings default to VS Code's extension list and search
  `.`, `copybooks/`, `cpy/`, and `copy/` under the project root (and the program's
  directory).
- `copybook/resolve` and `file/content` — che4z resolves COPY members on the **client**,
  not inside `server.jar`. The plugin searches the configured local folders for a matching
  basename + extension and returns the file text.

When upgrading che4z, update `che4zVersion` in `build.gradle.kts`, rebuild, and reinstall the
plugin. Reinstalling replaces the whole plugin directory, including the bundled server and grammar.


## Alternatives considered

Three other integration styles were prototyped and rejected:

- **Native in-process** (reflection over `server.jar`): no process isolation; reinvented IDE
  features; weaker UX than LSP.
- **Hybrid** (LSP + TextMate + in-process Structure View): Structure View reinvented what the
  platform already provides from che4z's document symbols over LSP.
- **Full-native** (no LSP; in-process engine for all features): flat `EmptyLexer` PSI forces
  bespoke bypasses for every language feature and hits a hard rename/refactoring ceiling.

The reusable typed bridge from the later prototypes is intentionally not kept here — this
plugin does not need it, and a module nothing depends on contradicts the lean goal.
