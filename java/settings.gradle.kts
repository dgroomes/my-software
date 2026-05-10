pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
}

rootProject.name = "java"

include(
    ":deduplicator",
    ":markdown-code-fence-reader",
    ":mcp-file-bookmarks",
    ":my-intellij-plugin"
)
