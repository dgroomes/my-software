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
    val constraints = platform("my:dependency-constraints")

    implementation(constraints)
    implementation("io.modelcontextprotocol:kotlin-sdk")

    runtimeOnly("org.slf4j:slf4j-simple")
}

application {
    mainClass.set("dgroomes.mcp_file_bookmarks.Mcp_file_bookmarksKt")
}
