plugins {
    id("my-base")
    id("org.jetbrains.intellij.platform")
}

repositories {
    intellijPlatform {
        defaultRepositories()
    }
}

dependencies {
    val constraints = platform("my:dependency-constraints")

    compileOnly(constraints)

    // SLF4J is already present in the Intellij Platform at runtime, so we only need it at compile time
    compileOnly("org.slf4j:slf4j-api")

    intellijPlatform {
        intellijIdea("2026.2.1")
    }
}

kotlin {
    jvmToolchain(21)
}

kotlin {
    sourceSets {
        main {
            languageSettings {
                // It's important to target the same version of Kotlin that powers the Intellij Platform at runtime.
                // We don't want to mistakenly code to newer Kotlin language features only to have the plugin fail at
                // runtime.
                //
                // See https://plugins.jetbrains.com/docs/intellij/using-kotlin.html#kotlin-standard-library
                // Keep this in sync with the "Bundled stdlib versions" table entry for the IntelliJ version
                // declared above.
                languageVersion = "2.4"
            }
        }
    }
}
