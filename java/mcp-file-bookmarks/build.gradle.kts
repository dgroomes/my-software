plugins {
    id("my-base")
    id("my-application")
    id("my-kotlin-serialization")
}

dependencies {
    implementation("io.modelcontextprotocol:kotlin-sdk")

    runtimeOnly("org.slf4j:slf4j-simple")
}

application {
    mainClass.set("dgroomes.mcp_file_bookmarks.Mcp_file_bookmarksKt")
}
