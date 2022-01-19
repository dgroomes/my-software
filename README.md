# my-config 

Personal configuration stuff including dot files, instructions and other configuration files.

## Organization

The repo is organized in the following directories:

### `mac-os/`

Start here. It includes my instructions for how I like to set up my macOS computers in the file `MACOS_SETUP.md`.

### `bash/`

My Bash config and notes about Bash auto-completion (I always forget how to set this up!).

### `iterm2/`

My iTerm2 config.

> iTerm2 is a terminal emulator for macOS that does amazing things.
> 
> -- <cite>https://iterm2.com</cite>

### `jetbrains/`

My configuration for JetBrains IDEs.

> Essential tools for software developers and teams
> 
> <cite>https://www.jetbrains.com</cite>

Build a `settings.zip` with `./build-jetbrains-settings.sh` and then import it into your Jetbrains IDE (e.g. Intellij, 
Android Studio) via <https://www.jetbrains.com/help/idea/sharing-your-ide-settings.html#import-export-settings>.

Conversely, to export more/updated settings *from* Intellij into this repo, refer to the same link to find the 
instructions on exporting the settings to a `settings.zip` file. Then, unzip `settings.zip` and commit the individual 
settings files to version control as desired (e.g. `settings/keymaps/mycustomkeymap.xml`, 
`settings/templates/mycustomlivetemplates.xml`).

### `karabiner/`

My configuration for the amazing tool *Karabiner-Elements* <https://github.com/tekezo/Karabiner-Elements>.

> Karabiner-Elements is a powerful utility for keyboard customization on macOS Sierra or later.
> 
> -- <cite>https://github.com/pqrs-org/Karabiner-Elements</cite>

### `navi/`

My [navi](https://github.com/denisidoro/navi) cheat sheets.

> An interactive cheatsheet tool for the command-line.
> 
> -- <cite>https://github.com/denisidoro/navi</cite>

### `starship/`

My config file for Starship.

> The minimal, blazing-fast, and infinitely customizable prompt for any shell!
>
> -- <cite>https://github.com/starship/starship</cite>

### `markdownlint/`

My configuration for `markdownlint` and `markdownlint-cli2`. 

> A Node.js style checker and lint tool for Markdown/CommonMark files.
> 
> -- <cite>https://github.com/DavidAnson/markdownlint</cite>

> A fast, flexible, configuration-based command-line interface for linting Markdown/CommonMark files with the markdownlint library
> 
> -- <cite>https://github.com/DavidAnson/markdownlint-cli2</cite>
