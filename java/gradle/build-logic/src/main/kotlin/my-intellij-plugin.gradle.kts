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
        intellijIdeaUltimate("2026.1.1")
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
                // But... for some reason the the "Bundled stdlib versions" table shows that 2026.1 bundles Kotlin
                // 2.3.20 but then the Intellij Platform Gradle plugin warns that 2.3 is experimental. Seems like a
                // contradiction. Let's go down to 2.2.
                languageVersion = "2.2"
            }
        }
    }
}
