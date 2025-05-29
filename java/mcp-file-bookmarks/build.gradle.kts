plugins {
    kotlin("jvm")
    kotlin("plugin.serialization")
    id("dgroomes.my-application")
}

sourceSets {
    main {
        java.srcDirs("src")
        kotlin.srcDirs("src")
        resources.srcDirs("resources")
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(libs.mcp.kotlin.sdk)
    runtimeOnly(libs.slf4j.simple)
}

application {
    mainClass.set("dgroomes.mcp_file_bookmarks.Mcp_file_bookmarksKt")
}
