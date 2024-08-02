plugins {
    alias(libs.plugins.kotlin.jvm)
    application
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

repositories {
    mavenCentral()
}

dependencies {
    implementation(libs.jackson.databind)
    implementation(libs.jetbrains.markdown)
    implementation(libs.slf4j.api)

    runtimeOnly(libs.jackson.kotlin)
    runtimeOnly(libs.logback.classic)

    testImplementation(libs.assertj)
    testImplementation(libs.junit.jupiter.api)

    testRuntimeOnly(libs.junit.jupiter.engine)
}

application {
    mainClass.set("dgroomes.markdown_code_fence_reader.Markdown_code_fence_readerKt")
}

tasks {
    named<JavaExec>("run") {
        jvmArgs = listOf("-Dlogback.configurationFile=logback.xml")
    }

    test {
        useJUnitPlatform()

        testLogging {
            showStandardStreams = true
            exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
        }
    }
}
