pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
}

rootProject.name = "java"

includeBuild("dependency-constraints")
includeBuild("build-logic")

include(
    ":deduplicator",
    ":markdown-code-fence-reader",
    ":mcp-file-bookmarks",
    ":my-intellij-plugin"
)
