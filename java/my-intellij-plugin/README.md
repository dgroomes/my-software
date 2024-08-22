# my-intellij-plugin

My personal IntelliJ plugin.


# Overview

I want an IntelliJ plugin that lets me quickly copy the names of files I have opened in my editor tabs. Ultimately, this
feature just helps me build a context of content that I'll use in a conversation with an AI chat (e.g. ChatGPT). I'll
use commandline tools to concatenate the contents of these files, and the contents of a user prompt, etc. This idea of
a "context builder to use for LLM conversations" is well described by a feature in the [*Zed* text editor](https://github.com/zed-industries/zed)
called the [Assistant Panel](https://zed.dev/docs/assistant/assistant-panel).


## Instructions

Follow these instructions to build and use the plugin:

1. Use Java 21
2. Build the plugin and run it
   * ```shell
     ../gradlew runIde
     ```
3. Build the plugin distribution
    * ```shell
      ../gradlew buildPlugin
      ```
    * The plugin is a ZIP file at `build/distributions/my-intellij-plugin.zip`.
4. Install the plugin
    * In Intellij, use the command pallet to find and execute the `Install Plugin from Disk` action. Find the ZIP file
      in the Finder window and select it. The plugin is now installed.


# Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [x] DONE Scaffold
* [ ] IN PROGRESS Implement
   * Wow, Claude Sonnet 3.5 one-shotted a working action... I want to clean it up, convert it to Kotlin, reconsider the
     language and UX, but that was really cool.
   * DONE Install instructions
