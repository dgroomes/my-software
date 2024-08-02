# markdown-code-fence-reader

Read code fences from Markdown files.


## Overview

There are often shell snippets described in "code fences" inside Markdown files. This program parses those snippets out
and returns them formatted in a JSON array. Extracting those snippets facilitates your ability to run those in your
shell, and this is exactly why I wrote this program.

In particular, I often write specific "how to build and run this project" instructions in my `README.md` files. The
instructions include shell commands authored inside code fences (triple back-ticks). This `README.md` is no exception
(look below). I usually execute these snippets by clicking the green play button that appears to the left of the
instructions. This button is in the "gutter" part of the editor window in Intellij. This is super convenient. Later, I
might re-execute the commands by using shell history (Ctrl-R) on the commandline. This is all perfectly fine, but I'd
prefer to compress this workflow even further. That part will come next (and this whole paragraph should go with it). 


## Instructions

1. Pre-requisite: Java 21
2. Run the tests
    * ```shell
      ../gradlew test
      ```
3. Build and run the program
    * ```shell
      ../gradlew run --args README.md
      ```
4. Build the program distribution
    * ```shell
      ../gradlew installDist
      ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project

* [x] DONE Wire in ~~commonmark-java~~ [jetbrains/markdown](https://github.com/JetBrains/markdown). commonmark-java
  is not parsing code blocks inside lists at all unfortunately and that's the exact use case I have.
* [x] DONE Return as JSON.
* [ ] Nushell side of things.
