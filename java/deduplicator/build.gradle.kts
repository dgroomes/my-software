plugins {
    kotlin("jvm")
    id("dgroomes.my-application")
}

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
    testImplementation(libs.assertj)
    testImplementation(libs.junit.jupiter.api)

    testRuntimeOnly(libs.junit.jupiter.engine)
}

application {
    mainClass.set("DeduplicatorKt")
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
