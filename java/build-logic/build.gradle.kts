plugins {
    `kotlin-dsl`
    `java-gradle-plugin`
}

gradlePlugin {
    plugins {
        create("myApplicationPlugin") {
            id = "dgroomes.my-application"
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
}
