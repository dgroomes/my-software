# markdown-code-fence-reader

Read code fences from Markdown files.

<img alt="markdown-code-fence-reader-screenshot.png" src="markdown-code-fence-reader-screenshot.png" width="1000"/>

## Overview

This program parses code fences (triple back-tick content) out of a Markdown file and returns them formatted in a JSON
array. Extracting those snippets facilitates your ability to run those in your shell, and this is exactly why I wrote
this program. See the accompanying Nushell code elsewhere in this repository.


## Instructions

1. Pre-requisite: Java 21
2. Run the tests
    * ```shell
      ../gradlew test
      ```
3. Build and install the program distribution with Homebrew
    * ```shell
      ../gradlew distTar
      ```
    * Update the formula in the `Formula/` directory in the root of this program. You will need to update the hash. Use
      the following command to compute the hash.
    * ```nushell
      open build/distributions/markdown-code-fence-reader.tar | hash sha256 | pbcopy
      ```


For a quicker build/install/use cycle, build and install the program distribution the "short-cut" way (I want to move
away from this if feasible and find a faster combination of commands and automation to do the Homebrew flow):

1. ```shell
   ../gradlew installDist
   ```
2. ```nushell
   ln -sf ('build/install/markdown-code-fence-reader/bin/markdown-code-fence-reader' | path expand) ~/.local/bin/markdown-code-fence-reader 
   ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [ ] ?
