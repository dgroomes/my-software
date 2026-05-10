import dgroomes.build_logic.AssertFilePresentTask

plugins {
    id("my-intellij-plugin")
}

dependencies {
    // The Kotlin stdlib that the client carries transitively duplicates the one IntelliJ
    // already provides at runtime; exclude it so the plugin distribution stays small.
    implementation(project(":nushell-client")) {
        exclude(group = "org.jetbrains.kotlin", module = "kotlin-stdlib")
    }
}

intellijPlatform {
    buildSearchableOptions = false
}

// =====================================================================================
// Native helper hand-off.
//
// The IntelliJ lexer for `.nu` files delegates to the official `nu_parser::lex` running in
// the sidecar at `rust/nu-lex/`. That project has its own README and its own build steps.
// =====================================================================================

val helperBinary = layout.projectDirectory.file("../../rust/nu-lex/target/release/nu-lex")

val assertNativeLexerBuilt by tasks.registering(AssertFilePresentTask::class) {
    description = "Assert the prebuilt nu-lex sidecar binary is present."
    group = "native helper"
    inputFile.set(helperBinary)
}

val packageNativeLexer by tasks.registering(Copy::class) {
    description = "Copy the prebuilt nu-lex sidecar into the plugin's resources tree."
    group = "native helper"
    dependsOn(assertNativeLexerBuilt)
    from(helperBinary)
    into(layout.buildDirectory.dir("generated-resources/native"))
}

sourceSets {
    main {
        resources.srcDir(layout.buildDirectory.dir("generated-resources"))
    }
}

tasks.named("processResources") {
    dependsOn(packageNativeLexer)
}
