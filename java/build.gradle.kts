plugins {

    // Declare (but "apply false") plugins that are used throughout the project. The important thing here is that this
    // one place declares the versions of these plugins, whereas when these plugins are applied in subprojects, those
    // declaration sites don't declare a version. If you try to include different versions of a Gradle plugin, you'll
    // get a warning like this:
    //
    //     The Kotlin Gradle plugin was loaded multiple times in different subprojects, which is not supported and may break the build.
    //
    // The effect of declaring a plugin with 'apply false' is that we get it on the classpath of the Gradle build.
    // Alternatively, you could include the plugin by way of the "dependencies { ... }" block in buildSrc. I've tried
    // every which way. They are all confusing to reason about.
    //
    // Also reference:
    //   - Gradle's support for Kotlin: https://docs.gradle.org/current/userguide/compatibility.html
    //   - Kotlin's support for Gradle https://kotlinlang.org/docs/gradle.html
    //
    kotlin("jvm") version "2.3.21" apply false
    kotlin("plugin.serialization") version "2.3.21" apply false
}
