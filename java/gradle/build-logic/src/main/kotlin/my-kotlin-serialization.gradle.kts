/*
This looks like a do-nothing wrapper around the Kotlin serialization plugin but it is a needed workaround.

As is, subprojects in the main build cannot write `kotlin("plugin.serialization")` without a version, because the Kotlin
serialization plugin is not a buildscript dependency of the main build. I could add the Kotlin serialization plugin as
a buildscript dependency in the main project by using 'buildSrc' and applying the 'dependency-constraints' platform
there. But, in my opinion, that creates a redundancy with 'build-logic' which is already doing that in its build.gradle.kts.

What we can do instead is just more of the same: what we've already done with the 'my-base' script plugin. Specifically
we make a script plugin (in this case 'my-kotlin-serialization') that encapsulates the version of the Kotlin
serialization plugin. The 'my-kotlin-serialization' plugin is an output artifact of 'build-logic' and any consuming
subprojects in the main of this artirfact change when the plugin changes. This is the general advantage of a 'build-logic'
project over 'buildSrc'. 'build-logic' let's you be really clear about outputs from build-logic and consumers in the main
build whereas with 'buildSrc', any change you make there automatically invalidates the configuration of all subprojects.
That's my understanding at least from posts form Gradle maintainers like this: https://discuss.gradle.org/t/buildsrc-vs-build-logic/46708/2
*/
plugins {
    kotlin("plugin.serialization")
}
