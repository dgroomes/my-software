plugins {
    kotlin("jvm")
    id("dgroomes.my-application")
}

/*
In Java/Kotlin Gradle projects, the default source set locations are:

  src/
  |-- main/
  |   |-- java/
  |   |-- kotlin/
  |   `-- resources/
  `-- test/
      |-- java/
      |-- kotlin/
      `-- resources/

But let's consolidate down to:

    src/
    resources/
    testSrc/
    testResources/
*/
sourceSets {
    main {
        java.srcDirs("src")
        kotlin.srcDirs("src")
        resources.srcDirs("resources")
    }

    test {
        java.srcDirs("testSrc")
        kotlin.srcDirs("testSrc")
        resources.srcDirs("testResources")
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(libs.jackson.databind)
    implementation(libs.jetbrains.markdown)

    runtimeOnly(libs.jackson.kotlin)

    testImplementation(libs.assertj)
    testImplementation(libs.junit.jupiter.api)

    testRuntimeOnly(libs.junit.jupiter.engine)
}

application {
    mainClass.set("dgroomes.markdown_code_fence_reader.Markdown_code_fence_readerKt")
}

tasks {
    test {
        useJUnitPlatform()

        testLogging {
            showStandardStreams = true
            exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
        }
    }
}
