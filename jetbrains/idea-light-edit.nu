#!/usr/bin/env nu --no-config-file
# Launch Intellij IDEA in "LightEdit" mode
#
# Launching LightEdit mode (https://www.jetbrains.com/help/idea/lightedit-mode.html) is really easy, and so this script
# does very little. The motivation for this script is to have a single executable ('idea-light-edit') that can be
# configured as the default editor for Nushell. As of Nushell 0.94, Nushell can't tolerate additional options for the
# value used in "$env.config.buffer_editor", like "idea -e". By contrast, Git tolerates "idea -e" for its "core.editor"
# configuration.

export def main [...args: string] {
    idea -e ...$args
}
