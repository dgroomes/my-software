# go

Go code that supports my personal workflows.


## Overview

To develop the Go code in this directory, I open this directory in the GoLand IDE. I won't bother trying to use Intellij
to develop Go. I've found, for example, that developing Python in Intellij is troublesome and I prefer to use PyCharm.
Same story for Android development, just use Android Studio.

Note: I might consider building and publishing binaries using GitHub Actions, and then installing them via HomeBrew, but
for now, `go install` should work fine for me.


## `my-launcher`

`my-launcher` launches Java programs by finding and invoking the correct version `java` installed on the system.
It depends on a `my-manifest.json` file that describes the minimum version of Java, the classpath, the main class, and
other Java system properties, etc. This is an alternative to the Gradle [`application` plugin](https://docs.gradle.org/current/userguide/application_plugin.html)
which creates a shell *start script* that encodes all this same info. I use the `application` plugin very frequently,
but now, I need to eject from Posix shell and get finer control and better interpretability. So I'm going with a "Go
binary + JSON manifest" as a Java program launcher.


## Instructions

1. Build the `my-launcher` binary:
    * ```shell
      go build ./...
      ```
    * Try it out by running the binary in various scenarios. If you are satisfied, then you can install it globally with
      the next step.
2. Build and install the binary to your `GOBIN`:
    * ```shell
      go install ./...
      ```
    * Now you can run `my-launcher` from anywhere in your terminal.


## Wish List

General clean-ups, TODOs and things I wish to implement for this project

* [x] DONE Scaffold a "hello world" program
* [x] DONE Implement `my-launcher`
