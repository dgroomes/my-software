# AGENTS.md

## Cursor Cloud specific instructions

This is a personal dotfiles/utilities monorepo with independent subprojects in Go, Java/Kotlin, JavaScript/TypeScript, and Python. There are no shared services or databases. Each subproject builds and runs independently.

### Subproject layout and build commands

| Subproject | Build | Test |
|---|---|---|
| `go/` (all Go packages) | `cd go && go build ./pkg/my-fuzzy-finder ./pkg/my-fuzzy-finder-lib ./pkg/my-java-launcher ./pkg/my-node-launcher` | `cd go && go test ./pkg/my-fuzzy-finder-lib/...` |
| `java/` (Gradle multi-project) | `cd java && PATH="$HOME/go/bin:$PATH" ./gradlew build` | `cd java && PATH="$HOME/go/bin:$PATH" ./gradlew test` |
| `javascript/mcp-rules` | `cd javascript/mcp-rules && npx tsc` | N/A (no test suite) |
| `javascript/my-obsidian-plugin` | `cd javascript/my-obsidian-plugin && npx tsc --noEmit` | N/A (no test suite) |
| `python/token-count` | `cd python/token-count && poetry install` | `echo "test" \| poetry run token-count` |

### Non-obvious caveats

- **Java build requires `my-java-launcher` on PATH.** The Gradle `findAndCopyMyLauncher` task searches PATH for the Go-built `my-java-launcher` binary. Before running `./gradlew build`, ensure `$HOME/go/bin` is on PATH (i.e. run `go install ./pkg/my-java-launcher` from the `go/` directory first).
- **`claude-sandboxed` Go package is macOS-only.** It uses macOS seatbelt sandbox APIs and will not compile on Linux. Exclude it when running `go test ./...` on Linux: use `go test ./pkg/my-fuzzy-finder-lib/...` or test individual packages.
- **`python/claude-proxy` requires Python ~3.13** which may not be available. The `python/token-count` project works with Python 3.12.
- **Poetry** is installed at `~/.local/bin/poetry`. Ensure `~/.local/bin` is on PATH.
- **The repo uses Nushell `do.nu` scripts** as the preferred build orchestration, but all builds work directly with the underlying tools (go, gradle, npm, poetry).
- **No linter configuration** is present at the repo level. TypeScript checking via `tsc --noEmit` serves as the lint step for JS projects.

### Nushell

Nushell (`nu`) is installed at `/usr/local/bin/nu` (v0.111.0, prebuilt musl binary). The user's config files from `nushell/` are installed into `~/.config/nushell/`:

- `config.nu` — adapted for Linux with nearly full parity to the original:
  - Starship prompt (installed at `/usr/local/bin/starship`, autoload adapted for Linux path)
  - zoxide (installed at `~/.local/bin/zoxide`)
  - Atuin shell history (installed at `~/.atuin/bin/atuin`)
  - LS_COLORS (vivid-generated, identical to repo)
  - GRADLE_OPTS, external bash completions, clipboard (`xclip` standing in for `pbcopy`/`pbpaste`)
  - All aliases: `ll`, `la`, `gs`, `gl`, `gw`, `fz`, `wt`, `da`, `c`/`p` (clipboard), `f`, etc.
- `scripts/*.nu` — all library scripts installed (zdu, lib, file-set, work-trees, subject, my-dir, node, open-jdk, postgres, bash-completer)
- `vendor/autoload/` — Starship, zoxide, and Atuin configs in `~/.local/share/nushell/vendor/autoload/` (also sourced explicitly from config.nu)
- `bash-completer.nu` adapted for Linux bash-completion paths (`/usr` instead of `/opt/homebrew`)
- `fd` is symlinked from `fdfind` → `/usr/local/bin/fd` so the `fd` wrapper in `lib.nu` works

**Not integrated** (macOS-only, no Linux equivalent):
- Homebrew keg activation for OpenJDK/Node.js (`advertise-installed-open-jdks`, `advertise-installed-nodes`)
- `code`, `cursor`, `xcode` commands (macOS `open -a` syntax)
- `explore-tart.nu` (Tart VM manager, macOS-only)
- `obsidian.nu` (depends on `~/repos/personal` directory structure)

To start Nushell: just run `nu`. The config loads automatically. To activate a project's `do.nu` overlay: `do activate` (or alias `da`).
