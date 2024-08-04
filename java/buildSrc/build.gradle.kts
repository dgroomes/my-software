plugins {
    `java-gradle-plugin`
}

gradlePlugin {
    plugins {
        create("myApplicationPlugin") {
            id = "dgroomes.my-application"
            implementationClass = "dgroomes.build_src.MyApplicationPlugin"
        }
    }
}

repositories {
    mavenCentral()
}

val jacksonVersion = "2.17.2" // Jackson releases: https://github.com/FasterXML/jackson/wiki/Jackson-Releases

dependencies {
    implementation("com.fasterxml.jackson.core:jackson-databind:$jacksonVersion")
}
