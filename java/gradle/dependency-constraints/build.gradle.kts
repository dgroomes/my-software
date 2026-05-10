plugins {
    `java-platform`
}

group = "my"

javaPlatform {
    allowDependencies()
}

dependencies {
    // JUnit releases: https://docs.junit.org/6.0.3/release-notes.html
    api(platform("org.junit:junit-bom:6.0.3"))

    constraints {
        // AssertJ releases: https://github.com/assertj/assertj-core/tags
        api("org.assertj:assertj-core:3.27.7")

        // Jackson releases: https://github.com/FasterXML/jackson/wiki/Jackson-Releases
        val jacksonVersion = "2.21.3"
        api("com.fasterxml.jackson.core:jackson-databind:$jacksonVersion")
        api("com.fasterxml.jackson.module:jackson-module-kotlin:$jacksonVersion")

        // JavaParser releases: https://github.com/javaparser/javaparser/releases
        api("com.github.javaparser:javaparser-core:3.28.1")

        // JetBrains Maven releases: https://central.sonatype.com/artifact/org.jetbrains/markdown?smo=true
        api("org.jetbrains:markdown:0.7.3")

        // Kotlin releases: https://kotlinlang.org/docs/releases.html
        val kotlinVersion = "2.3.21"
        api("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
        api("org.jetbrains.kotlin:kotlin-serialization:$kotlinVersion")

        // Kotlin SDK for MCP releases: https://github.com/modelcontextprotocol/kotlin-sdk/releases
        api("io.modelcontextprotocol:kotlin-sdk:0.5.0")

        // SLF4J releases: http://www.slf4j.org/news.html
        val slf4jVersion = "2.0.17"
        api("org.slf4j:slf4j-api:$slf4jVersion")
        api("org.slf4j:slf4j-simple:$slf4jVersion")

        // IntelliJ Platform Gradle Plugin releases: https://github.com/JetBrains/intellij-platform-gradle-plugin/releases
        api("org.jetbrains.intellij.platform:org.jetbrains.intellij.platform.gradle.plugin:2.16.0")
    }
}
