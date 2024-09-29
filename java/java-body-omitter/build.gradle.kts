plugins {
    kotlin("jvm")
    id("dgroomes.my-application")
}

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

repositories {
    mavenCentral()
}

dependencies {
    implementation(libs.javaparser.core)
}

application {
    mainClass.set("dgroomes.java_body_omitter.Java_body_omitterKt")
}
