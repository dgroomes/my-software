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
        api("com.fasterxml.jackson.core:jackson-databind:2.21.3")
        api("com.fasterxml.jackson.module:jackson-module-kotlin:2.21.3")

        // JavaParser releases: https://github.com/javaparser/javaparser/releases
        api("com.github.javaparser:javaparser-core:3.28.1")

        // JetBrains Maven releases: https://central.sonatype.com/artifact/org.jetbrains/markdown?smo=true
        api("org.jetbrains:markdown:0.7.3")

        // Kotlin SDK for MCP releases: https://github.com/modelcontextprotocol/kotlin-sdk/releases
        api("io.modelcontextprotocol:kotlin-sdk:0.5.0")

        // SLF4J releases: http://www.slf4j.org/news.html
        api("org.slf4j:slf4j-api:2.0.17")
        api("org.slf4j:slf4j-simple:2.0.17")
    }
}
