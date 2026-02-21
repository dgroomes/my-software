# jetbrains

My configuration for JetBrains IDEs (e.g. Intellij and Android Studio).


## Overview

I'm concerned about how much the settings grow and change over time due to new IDE releases. There's so much noise in the XML. I'm wondering if I should instead express some of these settings in natural language and provide instructions for doing them by hand. And/or preserving just a few of the XML version-controlled files for those that are a combination of **interprable** to me and lengthy enough to avoid having to do them by hand.

The `settings/` directory has a copy of my preferred IDE settings.


## Instructions

Follow these instructions to import the settings into a JetBrains IDE:

1. Build a `settings.zip` file
    * ```shell
      ./zip-settings.sh
      ```
    * The `settings.zip` file will be in the `build/` directory.
2. Import it into the IDE
    * Follow [these instructions in the Intellij docs](https://www.jetbrains.com/help/idea/sharing-your-ide-settings.html#import-export-settings)
  
Conversely, to export settings *from* Intellij into this repo, follow these instructions:

1. Export a `settings.zip` file from the IDE
    * Follow [these instructions in the Intellij docs](https://www.jetbrains.com/help/idea/sharing-your-ide-settings.html#import-export-settings)
    * Export the following items.
    * `Code Style (schemes)`
    * `Editor Colors`
    * `EqualsHashCodeTemplates`
    * `File Types`
    * `General`
    * `InlayHintsSettings, Editor`
    * `Keymaps`
    * `Keymaps (schemes)`
    * `Live templates (schemes)`
    * `LogHighlightingSettings`
    * `Look and Feel`
    * `Notifications`
    * `UI Settings`
    * `Vcs.Log.App, VCS`
2. Unzip it
    * ```shell
      unzip settings.zip -d settings-fresh-export
      ```
3. Review and commit the individual files
    * The settings are stored in multiple XML files (e.g. `settings/keymaps/mycustomkeymap.xml`, `settings/templates/mycustomlivetemplates.xml`)
      Review them before committing.


## Manual Settings

Configure these settings manually in the IDE.

1. Disable commit checks for new projects
   - [reference](https://stackoverflow.com/a/76513983)
   * `File` > `New Projects Setup` > `Settings for New Projects...` > `Version Control` > `Commit` and in `Advanced Commit Checks` uncheck `Analyze code` and `Check TODO`. The analysis is slow and for the TODOs I have long-lived ones by design. It's strategic to say "let me not do this thing now but consider it for later". I mean I guess I could use a different keyword that that?
