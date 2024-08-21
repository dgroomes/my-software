plugins {
    alias(libs.plugins.intellij.platform.gradle.plugin)
    alias(libs.plugins.kotlin.jvm)
}

repositories {
    mavenCentral()

    intellijPlatform {
        defaultRepositories()
    }
}

dependencies {
    // SLF4J is already present in the Intellij Platform at runtime, so we only need it at compile time
    compileOnly(libs.slf4j.api)

    intellijPlatform {
        intellijIdeaUltimate("2024.2")
        instrumentationTools()
    }
}

sourceSets {
    main {
        java.srcDirs("src")
        resources.srcDirs("resources")
    }

    test {
        java.srcDirs("testSrc")
        resources.srcDirs("testResources")
    }
}

kotlin {
    sourceSets {
        main {
            kotlin.srcDirs("src")
        }
        test {
            kotlin.srcDirs("testSrc")
        }
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
                languageVersion = "1.9"
            }
        }
    }
}
