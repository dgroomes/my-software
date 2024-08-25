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
* [x] DONE Implement
   * Wow, Claude Sonnet 3.5 oneshot a working action... I want to clean it up, convert it to Kotlin, reconsider the
     language and UX, but that was really cool.
   * DONE Install instructions
   * DONE Show open items in the tool window
   * DONE Extract "copy open files" logic to a service and use it from the action and from the window. IntelliJ
     says that while you can invoke an Action programmatically, [it recommends](https://plugins.jetbrains.com/docs/intellij/basic-action-system.html#executing-actions-programmatically)
     using a service instead.  
   * DONE Serialize to JSON
   * DONE Include the root project path
* [ ] Maybe write to a file instead (or also). I've thought a lot about the options. A custom URL scheme is cool to be
  able to trigger it from another process, and then there's also something I totally didn't expect is that you can use
  the built HTTP server which is usually used for serving static assets, but you can just do whatever you want with it.
  But this opens up your project data potentially more than you thought. Let's just keep the control inside the IDE to
  actually click the button.   
