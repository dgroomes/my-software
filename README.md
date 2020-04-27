# my-config 

Personal configuration stuff.

### macOS setup

My log of how I've set up my Mac is in `MACOS_SETUP.md`.

### Karabiner-Elements

`karabiner/`

<https://github.com/tekezo/Karabiner-Elements>

### JetBrains IDEs

`jetbrains/`

Build a `settings.zip` with `./build-jetbrains-settings.sh` and then import it into your Jetbrains IDE (e.g. Intellij, 
Android Studio) via <https://www.jetbrains.com/help/idea/sharing-your-ide-settings.html#import-export-settings>.

Conversely, to export more/updated settings *from* Intellij into this repo, refer to the same link to find the 
instructions on exporting the settings to a `settings.zip` file. Then, unzip `settings.zip` and commit the individual 
settings files to version control as desired (e.g. `settings/keymaps/mycustomkeymap.xml`, 
`settings/templates/mycustomlivetemplates.xml`) 