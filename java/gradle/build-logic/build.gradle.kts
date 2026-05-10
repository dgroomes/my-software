plugins {
    `kotlin-dsl`
    `java-gradle-plugin`
}

gradlePlugin {
    plugins {
        create("myApplicationPlugin") {
            id = "my-application"
            implementationClass = "dgroomes.build_logic.MyApplicationPlugin"
        }
    }
}

repositories {
    gradlePluginPortal()
    mavenCentral()
}

dependencies {
    val constraints = platform("my:dependency-constraints")

    implementation(constraints)
    implementation("com.fasterxml.jackson.core:jackson-databind")

    // Declare the implementation dependencies that represent plugin. This explains how we can omit the version
    // specifier when declaring and applying these plugins in the 'plugins {}' block in the precompiled script plugins.
    implementation("org.jetbrains.kotlin:kotlin-gradle-plugin")
    implementation("org.jetbrains.kotlin:kotlin-serialization")
    implementation("org.jetbrains.intellij.platform:org.jetbrains.intellij.platform.gradle.plugin")
}
