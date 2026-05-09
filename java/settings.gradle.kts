pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }

    plugins {
        kotlin("jvm") version "2.2.21"
        kotlin("plugin.serialization") version "2.2.21"
    }
}

rootProject.name = "java"

include(
    ":deduplicator",
    ":markdown-code-fence-reader",
    ":mcp-file-bookmarks",
    ":my-intellij-plugin"
)
