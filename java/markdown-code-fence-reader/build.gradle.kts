plugins {
    id("my-base")
    id("my-application")
}

dependencies {
    implementation("com.fasterxml.jackson.core:jackson-databind")
    implementation("org.jetbrains:markdown")

    runtimeOnly("com.fasterxml.jackson.module:jackson-module-kotlin")
}

application {
    mainClass.set("dgroomes.markdown_code_fence_reader.Markdown_code_fence_readerKt")
}
