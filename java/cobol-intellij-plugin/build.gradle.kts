// WARNING: Unedited AI output

import org.gradle.api.tasks.Input
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.TaskAction
import org.jetbrains.intellij.platform.gradle.tasks.PrepareSandboxTask
import java.net.URI

plugins {
    id("my-intellij-plugin")
}

dependencies {
    intellijPlatform {
        // Compile against the bundled TextMate plugin API (TextMateBundleProvider).
        bundledPlugin("org.jetbrains.plugins.textmate")
    }
}

intellijPlatform {
    buildSearchableOptions = false
}

tasks.named<JavaExec>("runIde") {
    // Open the sample COBOL project in the sandbox IDE.
    args(layout.projectDirectory.dir("sample").asFile.absolutePath)
}

// =====================================================================================
// che4z COBOL LSP server + TextMate grammar (downloaded from official GitHub releases;
// not vendored).
//
// Release assets are VS Code VSIX packages. The platform-neutral VSIX contains:
//   extension/server/jar/server.jar          — Java LSP (LangServerBootstrap)
//   extension/package.json + syntaxes/       — TextMate / VS Code grammar bundle
// =====================================================================================

val che4zVersion = "2.5.1"
val che4zVsixUrl =
    "https://github.com/eclipse-che4z/che-che4z-lsp-for-cobol/releases/download/" +
        "$che4zVersion/cobol-language-support-$che4zVersion.vsix"

val che4zVsix = layout.buildDirectory.file("che4z/cobol-language-support-$che4zVersion.vsix")

abstract class DownloadUrl : DefaultTask() {
    @get:Input
    abstract val url: Property<String>

    @get:OutputFile
    abstract val destination: RegularFileProperty

    @TaskAction
    fun download() {
        val dest = destination.get().asFile
        dest.parentFile.mkdirs()
        URI(url.get()).toURL().openStream().use { input ->
            dest.outputStream().use { output -> input.copyTo(output) }
        }
    }
}

val downloadChe4zVsix by tasks.registering(DownloadUrl::class) {
    description = "Download the che4z COBOL Language Support VSIX from GitHub Releases."
    group = "che4z"
    url.set(che4zVsixUrl)
    destination.set(che4zVsix)
}

val extractChe4zServerJar by tasks.registering(Copy::class) {
    description = "Extract server.jar from the che4z VSIX."
    group = "che4z"
    dependsOn(downloadChe4zVsix)
    from(zipTree(che4zVsix)) {
        include("extension/server/jar/server.jar")
        eachFile {
            relativePath = RelativePath(true, "server.jar")
        }
        includeEmptyDirs = false
    }
    into(layout.buildDirectory.dir("che4z/server"))
}

val che4zTextMateDir = layout.buildDirectory.dir("che4z/textmate")

val extractChe4zCobolGrammar by tasks.registering(Copy::class) {
    description = "Extract che4z's COBOL.tmLanguage.json from the VSIX."
    group = "che4z"
    dependsOn(downloadChe4zVsix)
    from(zipTree(che4zVsix)) {
        include("extension/syntaxes/COBOL.tmLanguage.json")
        eachFile {
            relativePath = RelativePath(true, relativePath.lastName)
        }
        includeEmptyDirs = false
    }
    into(che4zTextMateDir.map { it.dir("syntaxes") })
}

val writeChe4zTextMateManifest by tasks.registering {
    description = "Write a slim VS Code package.json IntelliJ's TextMate reader accepts."
    group = "che4z"
    dependsOn(extractChe4zCobolGrammar)
    val manifest = che4zTextMateDir.map { it.file("package.json") }
    val version = che4zVersion
    inputs.property("che4zVersion", version)
    outputs.file(manifest)
    doLast {
        // IntelliJ's TextMate VS Code reader is picky:
        // - unknown grammar keys like che4z's `injectTo` break package.json decoding
        // - language `configuration` files must include a `comments` object; che4z's
        //   lang-config.json does not, and loading it aborts bundle registration with
        //   "unknown format" (after the grammar may already have been applied).
        // So we ship only language + grammar entries. The .tmLanguage.json is upstream.
        manifest.get().asFile.writeText(
            """
            {
              "name": "che4z-cobol",
              "version": "$version",
              "contributes": {
                "languages": [
                  {
                    "id": "cobol",
                    "extensions": [".cbl", ".cob", ".cobol", ".cpy", ".copy"],
                    "aliases": ["COBOL"]
                  }
                ],
                "grammars": [
                  {
                    "language": "cobol",
                    "scopeName": "source.cobol",
                    "path": "./syntaxes/COBOL.tmLanguage.json"
                  }
                ]
              }
            }
            """.trimIndent() + "\n"
        )
    }
}

// Place server.jar and the TextMate bundle in the plugin directory, next to `lib/`.
// The distribution is fully assembled at build time.
tasks.named<PrepareSandboxTask>("prepareSandbox") {
    dependsOn(writeChe4zTextMateManifest)
    from(extractChe4zServerJar) {
        into(pluginName.map { "$it/che4z" })
    }
    from(che4zTextMateDir) {
        into(pluginName.map { "$it/che4z/textmate" })
    }
}
