# jetbrains

My configuration for JetBrains IDEs (e.g. Intellij and Android Studio).

The `settings/` directory has a copy of my preferred IDE settings.

## Instructions

Follow these instructions to import the settings into a JetBrains IDE:

1. Build a `settings.zip` file
    * `./zip-settings.sh`
    * The `settings.zip` file will be in the `build/` directory.
1. Import it into the IDE
    * Follow [these instructions in the Intellij docs](https://www.jetbrains.com/help/idea/sharing-your-ide-settings.html#import-export-settings)
  
Conversely, to export settings *from* Intellij into this repo, follow these instructions:

1. Export a `settings.zip` file from the IDE
    * Follow [these instructions in the Intellij docs](https://www.jetbrains.com/help/idea/sharing-your-ide-settings.html#import-export-settings)
2. Unzip it
    * `unzip settings.zip`
3. Review and commit the individual files
    * The settings are stored in multiple XML files (e.g. `settings/keymaps/mycustomkeymap.xml`, `settings/templates/mycustomlivetemplates.xml`)
      Review them before committing.
