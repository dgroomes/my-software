plugins {
    alias(libs.plugins.intellij.platform.gradle.plugin)
    kotlin("jvm")
}

repositories {
    mavenCentral()

    intellijPlatform {
        defaultRepositories()
        intellijDependencies()
    }
}

dependencies {
    // The Kotlin stdlib that the client carries transitively duplicates the one IntelliJ
    // already provides at runtime; exclude it so the plugin distribution stays small.
    implementation(project(":nushell-client")) {
        exclude(group = "org.jetbrains.kotlin", module = "kotlin-stdlib")
    }

    intellijPlatform {
        // The IntelliJ LSP API is only shipped in commercial JetBrains IDEs.
        intellijIdeaUltimate("2026.1")
    }
}

kotlin {
    jvmToolchain(21)
    sourceSets {
        main {
            languageSettings {
                // Target the version of Kotlin that powers the IntelliJ Platform at runtime.
                languageVersion = "2.2"
            }
        }
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

val helperBinary: java.io.File =
    rootDir.parentFile.resolve("rust/nu-lex/target/release/nu-lex")

val assertNativeLexerBuilt by tasks.registering {
    description = "Assert the prebuilt nu-lex sidecar binary is present."
    group = "native helper"
    inputs.property("helperBinary", helperBinary.absolutePath)
    doLast {
        check(helperBinary.exists()) {
            "The nu-lex sidecar binary is missing: $helperBinary\n\n" +
            "Build it first by running, from the repository root:\n\n" +
            "    cd rust/nu-lex\n" +
            "    cargo build --release\n\n" +
            "See rust/nu-lex/README.md for details. This Gradle build intentionally does " +
            "not orchestrate the Rust build."
        }
    }
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
