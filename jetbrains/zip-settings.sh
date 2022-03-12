#!/bin/bash
# Build a 'settings.zip' which can be imported into a JetBrains IDE

set -eu

# Bash trick to get the directory containing the script. See https://stackoverflow.com/a/246128
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

BUILD_DIR="$CURRENT_DIR/build/settings"
if [[ -d "$BUILD_DIR" ]]; then
    # Clean up existing stuff
    rm "$BUILD_DIR"/settings.zip
    find "$BUILD_DIR" -name '*.xml' -delete -print
else
    mkdir -p "$BUILD_DIR"
fi

# Prepare the contents that will be saved into the resulting 'settings.zip' file
cp -r "$CURRENT_DIR/settings/"* "$BUILD_DIR"

# The JetBrains IDEs will complain if they don't see this file (case sensitive and must be executable!) when importing a
# 'settings.zip' file
INTELLIJ_FILE="$BUILD_DIR/IntelliJ IDEA Global Settings"
touch "$INTELLIJ_FILE"
chmod +x "$INTELLIJ_FILE"

# Create the 'settings.zip' file
zip -r "$BUILD_DIR/settings.zip" "$BUILD_DIR"

echo "An Intellij settings file (settings.zip) was created at '$BUILD_DIR'. It can be imported into any JetBrains IDE."
