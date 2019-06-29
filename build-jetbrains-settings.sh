#!/bin/bash
# Build a 'settings.zip' which can imported into a JetBrains IDE

ROOT_DIR="$PWD"
BUILD_DIR=build/jetbrains/settings
if [[ -d "$BUILD_DIR" ]]; then
    # Clean up existing stuff
    rm "$BUILD_DIR"/settings.zip
    find "$BUILD_DIR" -name '*.xml' -delete -print
else
    mkdir -p "$BUILD_DIR"
fi

# Prepare the contents that will be saved into the resulting 'settings.zip' file
cp -r "$ROOT_DIR/jetbrains/settings/"* "$BUILD_DIR"
cd "$BUILD_DIR"
# The JetBrains IDEs will complain if they don't see this file (case sensitive and must be executable!) when importing a
# 'settings.zip' file
INTELLIJ_FILE='IntelliJ IDEA Global Settings'
touch "$INTELLIJ_FILE"
chmod +x "$INTELLIJ_FILE"

# Create the 'settings.zip' file
zip -r settings.zip .

# Navigate back
cd "$ROOT_DIR"