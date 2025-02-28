plugins {
    kotlin("jvm")
    id("dgroomes.my-application")
}

sourceSets {
    main {
        java.srcDirs("src", "srcGen")
        kotlin.srcDirs("src", "srcGen")
        resources.srcDirs("resources")
    }

    test {
        java.srcDirs("srcTest")
        kotlin.srcDirs("srcTest")
        resources.srcDirs("testResources")
    }
}


repositories {
    mavenCentral()
}

dependencies {
    implementation(libs.javaparser.core)
    implementation(libs.protobuf.java)

    testImplementation(libs.junit.jupiter.api)
    testImplementation(libs.assertj)
    testRuntimeOnly(libs.junit.jupiter.engine)
}

application {
    mainClass.set("dgroomes.java_body_omitter.Java_body_omitterKt")
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
