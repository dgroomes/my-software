# Environment Report

Bill of materials for the development environment set up for the `my-software` repository.


## Base VM

| Property | Value |
|---|---|
| OS | Ubuntu 24.04.4 LTS (Noble Numbat) |
| Kernel | `6.1.147` x86_64 |
| CPUs | 4 |
| RAM | 16 GB |
| Disk | 126 GB (overlay filesystem) |
| User | `ubuntu` (home: `/home/ubuntu`) |
| Workspace | `/workspace` (git clone of `dgroomes/my-software`) |
| Runtime | Cursor Cloud Agent (Firecracker VM) |


## Pre-existing tools (came with the VM image)

These were already installed on the VM before any setup work. They are part of the base Cursor Cloud
Agent image and are not managed by this repository.

| Tool | Version | Location | Notes |
|---|---|---|---|
| Go | 1.22.2 | system | Matches `go.mod` requirement of 1.22.5 (toolchain auto-downloads) |
| OpenJDK | 21.0.10 | `/usr/lib/jvm/java-21-openjdk-amd64` | Ubuntu package; used by Gradle for the `java/` subprojects |
| Node.js | 22.22.1 | `~/.nvm/versions/node/v22.22.1/bin/node` | Managed by nvm |
| npm | 10.9.4 | via nvm | Used for `javascript/` subprojects |
| pnpm | 10.32.1 | via nvm | Not used by this repo (repo uses npm) |
| Python | 3.12.3 | `/usr/bin/python3` | System Python; used by `python/token-count` |
| Rust | 1.83.0 | `/usr/local/cargo/bin/rustc` | Not used by repo, but was useful for potential source builds |
| Cargo | 1.83.0 | `/usr/local/cargo/bin/cargo` | Same as above |
| Git | 2.43.0 | system | Used everywhere |
| Bash | 5.2.21 | `/usr/bin/bash` | Used by bash-completion integration |
| xclip | system | `/usr/bin/xclip` | Used as Linux substitute for macOS `pbcopy`/`pbpaste` |
| nvm | — | `~/.nvm` | Node version manager (pre-installed) |


## Installed tools (added during setup)

Everything below was installed by the agent during the setup session. Each entry explains what
was installed, where, why, and how to reproduce the installation.

### Nushell

| Property | Value |
|---|---|
| Version | 0.111.0 |
| Location | `/usr/local/bin/nu` |
| Binary type | Static-linked musl ELF (x86_64) |
| Why | The repo's preferred build orchestration uses Nushell `do.nu` scripts. The user's shell config, aliases, and custom commands are all written in Nushell. |

**How it was installed:**

```bash
curl -sL -o /tmp/nu.tar.gz \
  https://github.com/nushell/nushell/releases/download/0.111.0/nu-0.111.0-x86_64-unknown-linux-musl.tar.gz
tar xzf /tmp/nu.tar.gz -C /tmp
sudo cp /tmp/nu-0.111.0-x86_64-unknown-linux-musl/nu /usr/local/bin/nu
sudo chmod +x /usr/local/bin/nu
```

**How to reproduce in the future:** Check the [Nushell releases page](https://github.com/nushell/nushell/releases)
for the latest `x86_64-unknown-linux-musl` tarball. The musl build is fully static and requires
no shared libraries.


### Starship (prompt)

| Property | Value |
|---|---|
| Version | 1.24.2 |
| Location | `/usr/local/bin/starship` |
| Why | The user's Nushell config integrates Starship for a rich prompt showing git branch, language versions, and directory context. |

**How it was installed:**

```bash
curl -sS https://starship.rs/install.sh | sudo sh -s -- --yes
```

**How to reproduce:** The official Starship installer auto-detects the platform. It places the
binary in `/usr/local/bin/`.


### zoxide (directory jumper)

| Property | Value |
|---|---|
| Version | 0.9.9 |
| Location | `~/.local/bin/zoxide` |
| Why | The user's Nushell config uses zoxide for frecency-based directory jumping (the `z` command in `vendor/autoload/zoxide.nu`). |

**How it was installed:**

```bash
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
```

**How to reproduce:** The official installer downloads the correct binary for the platform and
places it in `~/.local/bin/`. Make sure `~/.local/bin` is on PATH.


### Atuin (shell history)

| Property | Value |
|---|---|
| Version | 18.13.6 |
| Location | `~/.atuin/bin/atuin` |
| Why | The user's Nushell config integrates Atuin for enhanced shell history with Ctrl+R search (configured in `vendor/autoload/atuin.nu`). |

**How it was installed:**

```bash
curl -sSf https://setup.atuin.sh | sh -s -- --yes --disable-login
```

**How to reproduce:** The official installer places the binary in `~/.atuin/bin/`. The `--disable-login`
flag skips the cloud sync account setup (not needed for local dev).


### fd (fast file finder)

| Property | Value |
|---|---|
| Version | 9.0.0 |
| Location | `/usr/bin/fdfind` (symlinked to `/usr/local/bin/fd`) |
| Why | The user's `lib.nu` wraps `fd` for structured Nushell output. Commands like `word-counts-of-files` and `file-set add` depend on it. |

**How it was installed:**

```bash
sudo apt-get install -y fd-find
sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd
```

**Note:** On Ubuntu/Debian, the package is `fd-find` and the binary is `fdfind` (to avoid a name
conflict with another package). The symlink at `/usr/local/bin/fd` makes the user's Nushell
scripts work without modification.


### bash-completion (v2)

| Property | Value |
|---|---|
| Version | 2.11-8 |
| Location | `/usr/share/bash-completion/` |
| Why | The user's `bash-completer.nu` script provides Nushell tab-completions by delegating to bash-completion functions. The `one-shot-bash-completion.bash` script sources this library. |

**How it was installed:**

```bash
sudo apt-get install -y bash-completion
```


### Poetry (Python package manager)

| Property | Value |
|---|---|
| Version | 2.3.2 |
| Location | `~/.local/bin/poetry` |
| Why | The `python/token-count` and `python/claude-proxy` subprojects use Poetry for dependency management (each has a `pyproject.toml` with `poetry-core` as the build backend). |

**How it was installed:**

```bash
pip install poetry
```

**Note:** `~/.local/bin` must be on PATH for `poetry` to be found.


### my-java-launcher (Go binary)

| Property | Value |
|---|---|
| Version | Built from source in this repo |
| Location | `~/go/bin/my-java-launcher` |
| Why | The Gradle build for `java/` subprojects has a `findAndCopyMyLauncher` task that searches PATH for this binary. Without it, `./gradlew build` fails. |

**How it was installed:**

```bash
cd /workspace/go && go install ./pkg/my-java-launcher
```

**This is a critical dependency.** The Java/Kotlin build will fail without this Go binary on PATH.
`~/go/bin` must be on PATH (it is by default in this environment).


## Nushell configuration

The user's Nushell configuration from the `nushell/` directory in the repo was installed into the
Nushell config locations. This is the most complex part of the setup because the original config
targets macOS with Homebrew, and adaptations were needed for Linux.

### Files installed

**`~/.config/nushell/config.nu`** — Main configuration file. This is an *adapted copy* of `nushell/config.nu`
from the repo. Changes from the original:

| Original (macOS) | Adapted (Linux) |
|---|---|
| PATH includes `/opt/homebrew/bin`, `~/Library/Application Support/JetBrains/...`, etc. | PATH includes `~/.atuin/bin`, `~/.local/bin`, `~/.cargo/bin`, `~/go/bin`, `~/.local/npm/bin` |
| `$env.HOMEBREW_PREFIX = "/opt/homebrew"` and related Homebrew env vars | Removed (no Homebrew on Linux) |
| `pbcopy` / `pbpaste` aliases (macOS clipboard) | Replaced with `xclip -selection clipboard` wrappers |
| `$env.config.buffer_editor = "subl"` | Changed to `"vim"` |
| `advertise-installed-open-jdks` / `advertise-installed-nodes` calls | Removed (depend on Homebrew keg layout) |
| `source` of autoload scripts via Nushell's `vendor/autoload/` mechanism | Explicit `source` statements in config.nu (more reliable in non-interactive contexts) |
| `code`, `cursor`, `xcode` commands (macOS `open -a` syntax) | Not included |
| Everything else | Preserved as-is (aliases, color config, LS_COLORS, GRADLE_OPTS, do activate, history settings, etc.) |

**`~/.config/nushell/scripts/`** — All library scripts copied from `nushell/scripts/`:

| File | Purpose | Linux compatibility |
|---|---|---|
| `zdu.nu` | Zero-dependency utilities (`repos`, `coalesce`, `whichx`, `err`, `file-name`, `compress-home`, `epoch-into-datetime`) | Full |
| `lib.nu` | Main command library (`gw`, `fz`, `fd`, `cat-with-frontmatter`, `dirty-git-projects`, `run-from-readme`, `dedupe`, `wikipedia`, `stash`, `comma-per-thousand`, `git-switch-default-pull`, `git-checkout-as-my`, etc.) | Full (except `code`/`cursor`/`xcode` which are macOS-only) |
| `file-set.nu` | LLM context bundling (`file-set init`, `file-set add`, `file-set validate`, `file-set summarize`) | Full |
| `work-trees.nu` | Git worktree management (`work-tree list`, `work-tree switch`, `work-tree add`) | Full |
| `subject.nu` | Subject/workspace creation (`new-subject`) | Full |
| `my-dir.nu` | `.my` directory scaffolding (`my-dir-init`) | Full |
| `bash-completer.nu` | External bash-completion integration | **Adapted**: changed `BASH_COMPLETION_INSTALLATION_DIR` from `/opt/homebrew/opt/bash-completion@2` to `/usr` and `XDG_DATA_DIRS` from `/opt/homebrew/share` to `/usr/share` |
| `node.nu` | Node.js keg management (`activate-my-node`, `advertise-installed-nodes`) | Loads but commands error (depends on Homebrew keg layout) |
| `open-jdk.nu` | OpenJDK keg management (`activate-my-open-jdk`, `advertise-installed-open-jdks`) | Loads but commands error (depends on Homebrew keg layout) |
| `postgres.nu` | Postgres keg activation | Loads but commands error (depends on Homebrew keg layout) |
| `explore-tart.nu` | Tart VM management | macOS-only; loads but all commands are non-functional |
| `obsidian.nu` | Obsidian vault creation | Depends on `~/repos/personal` directory; non-functional |

**`~/.config/nushell/one-shot-bash-completion.bash`** — Bash script for one-shot completion lookups,
copied as-is from `nushell/one-shot-bash-completion.bash`.

**`~/.local/share/nushell/vendor/autoload/`** — Autoload scripts:

| File | Source | Adaptation |
|---|---|---|
| `starship.nu` | `nushell/vendor/autoload/starship.nu` | All `/opt/homebrew/bin/starship` paths → `/usr/local/bin/starship` |
| `zoxide.nu` | `nushell/vendor/autoload/zoxide.nu` | None needed (uses `zoxide` command without hardcoded paths) |
| `atuin.nu` | `nushell/vendor/autoload/atuin.nu` | None needed (uses `atuin` command without hardcoded paths) |


## Project dependency state

These are per-subproject dependency installations, not system-level tools.

| Subproject | What was installed | Location | Command to refresh |
|---|---|---|---|
| `go/` | Go module cache | `~/go/pkg/mod/` | `cd go && go mod download` |
| `go/` | `my-java-launcher` binary | `~/go/bin/my-java-launcher` | `cd go && go install ./pkg/my-java-launcher` |
| `java/` | Gradle 8.5 distribution | `~/.gradle/wrapper/dists/gradle-8.5-bin/` | Auto-downloaded by `./gradlew` |
| `java/` | Kotlin compiler, IntelliJ SDK, etc. | `~/.gradle/caches/` | Auto-downloaded by `./gradlew build` |
| `javascript/mcp-rules` | 84 npm packages | `javascript/mcp-rules/node_modules/` | `cd javascript/mcp-rules && npm install` |
| `javascript/my-obsidian-plugin` | 12 npm packages | `javascript/my-obsidian-plugin/node_modules/` | `cd javascript/my-obsidian-plugin && npm install` |
| `python/token-count` | Poetry virtualenv with tiktoken | `~/.cache/pypoetry/virtualenvs/token-count-*` | `cd python/token-count && poetry install` |


## What was NOT installed (and why)

| Component | Reason |
|---|---|
| Homebrew | Linux environment; all tools installed via apt, official installers, or prebuilt binaries |
| Python 3.13 | Not available on Ubuntu 24.04; `python/claude-proxy` requires it but `python/token-count` works with 3.12 |
| Nushell plugins (`nu_plugin_*`) | The prebuilt release includes them but they weren't registered; not needed for the core workflow |
| Obsidian | Desktop app; the `obsidian.nu` script loads but its commands are non-functional without `~/repos/personal` |
| Docker | Already available in the VM environment; no installation needed |
| IntelliJ IDEA | The `my-intellij-plugin` subproject builds via Gradle (headless); no IDE needed |
| Tart (VM manager) | macOS-only tool; `explore-tart.nu` loads but is non-functional |


## Reproducibility: how to set up this environment from scratch

For a future orchestrator setting up a fresh Ubuntu 24.04 VM for this repository:

```bash
# 1. System packages
sudo apt-get update
sudo apt-get install -y fd-find bash-completion xclip
sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd

# 2. Nushell (check https://github.com/nushell/nushell/releases for latest)
curl -sL -o /tmp/nu.tar.gz \
  https://github.com/nushell/nushell/releases/download/0.111.0/nu-0.111.0-x86_64-unknown-linux-musl.tar.gz
tar xzf /tmp/nu.tar.gz -C /tmp
sudo cp /tmp/nu-0.111.0-x86_64-unknown-linux-musl/nu /usr/local/bin/nu

# 3. Starship prompt
curl -sS https://starship.rs/install.sh | sudo sh -s -- --yes

# 4. zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# 5. Atuin
curl -sSf https://setup.atuin.sh | sh -s -- --yes --disable-login

# 6. Poetry
pip install poetry

# 7. Go binary needed by Java build
cd /workspace/go && go install ./pkg/my-java-launcher

# 8. Nushell config (copy from repo and adapt, or use the snapshot)
mkdir -p ~/.config/nushell/scripts ~/.local/share/nushell/vendor/autoload
cp /workspace/nushell/scripts/*.nu ~/.config/nushell/scripts/
cp /workspace/nushell/one-shot-bash-completion.bash ~/.config/nushell/
# config.nu, starship.nu, bash-completer.nu need path adaptations (see above)

# 9. Project dependencies
cd /workspace/javascript/mcp-rules && npm install
cd /workspace/javascript/my-obsidian-plugin && npm install
cd /workspace/python/token-count && PATH="$HOME/.local/bin:$PATH" poetry install
```


## Update script (runs on every VM startup)

The SetupVmEnvironment update script handles only dependency refresh, not system tool
installation (which is baked into the snapshot):

```bash
pip install --quiet poetry
cd go && go install ./pkg/my-java-launcher
cd javascript/mcp-rules && npm install
cd /workspace/javascript/my-obsidian-plugin && npm install
cd /workspace/python/token-count && PATH="$HOME/.local/bin:$PATH" poetry install --quiet
```
