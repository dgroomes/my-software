plugins {
    kotlin("jvm")
}

sourceSets {
    main {
        java.srcDirs("src")
        kotlin.srcDirs("src")
        resources.srcDirs("resources")
    }
}

repositories {
    mavenCentral()
}

dependencies {
    // Jackson is bundled in the IntelliJ Platform (`lib/lib-client.jar`, unshaded), so when
    // this library is consumed from the IntelliJ plugin the runtime classes already exist.
    // We declare Jackson `compileOnly` so we don't drag a duplicate copy into the plugin
    // distribution. Standalone JVM consumers should add their own Jackson dependency.
    compileOnly(libs.jackson.databind)
    compileOnly(libs.jackson.kotlin)
}

kotlin {
    jvmToolchain(21)
}
