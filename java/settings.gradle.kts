pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
}

rootProject.name = "java"

includeBuild("gradle/dependency-constraints")
includeBuild("gradle/build-logic")

include(
    ":deduplicator",
    ":markdown-code-fence-reader",
    ":mcp-file-bookmarks",
    ":my-intellij-plugin",
    ":nushell-client",
    ":nushell-intellij-plugin",
)
