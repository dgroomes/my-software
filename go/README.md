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


## `my-fuzzy-finder`

`my-fuzzy-finder` is a commandline fuzzy finder that has a JSON API. It's designed to have a similar user experience to
`fzf` but supports input/output expressed in JSON instead of newline-delimited strings.

I think `fzf` really got the UX right, and it's been replicated in many tools. The main feature I'm missing from `fzf`
is the ability to have structured output. I use [Nushell](https://www.nushell.sh/) which is a shell that uses
structured data, and the more that my tools can support structured data, the better.

`my-fuzzy-finder` is a TUI (text user interface) program built using these excellent projects:

- The [Bubble Tea](https://github.com/charmbracelet/bubbletea) TUI framework
- The [Bubbles](https://github.com/charmbracelet/bubbles) TUI component library
- The "fuzzy" library <https://github.com/sahilm/fuzzy>.


## Instructions

Follow these instructions to build, run and install my software.

1. Build and run the `my-fuzzy-finder` program with the example data:
    * ```shell
      go run my-software/pkg/my-fuzzy-finder --example
      ```
    * Next, try fuzzy finding among the filenames in the current directory.
    * ```nushell
      ls | get name | str join (char newline) | go run my-software/pkg/my-fuzzy-finder
      ```
    * Next, try a similar thing but with JSON output.
    * ```nushell
      ls | get name | str join (char newline) | go run my-software/pkg/my-fuzzy-finder --json-out | from json
      ```
    * Finally, try the program and enable debugging. The logs are printed to a local `my-fuzzy-finder.log` file.
    * ```nushell
      go run my-software/pkg/my-fuzzy-finder --example --debug
      ```
2. Build all executables:
    * ```nushell
      mkdir bin; go build -o bin  './...'
      ```
    * The executables (i.e. `my-launcher`, `my-fuzzy-finder`) will be in the `bin/` directory. Try them out as needed to
      do validation and exploration. If you are satisfied, then you can install the executables globally with the next
      step.
3. Build and install the executables to your `GOBIN`:
    * ```shell
      go install './...'
      ```
    * Now you can run the executables, like `my-launcher`, from anywhere on your system.


## Wish List

General clean-ups, TODOs and things I wish to implement for this project

* [x] DONE Scaffold a "hello world" program
* [x] DONE Implement `my-launcher`
* [x] DONE Implement `my-fuzzy-finder`
    * DONE I need to start paring things down. Start with getting rid of most keybindings.
      * DONE Let's get rid of the pagination first.
    * DONE "enter" to complete the program.
    * DONE "esc" to quit the program without a selection. Use an exit status.
    * DONE (removed) What is the status message?
    * DONE Drop the spinner
    * DONE Copy in textinput and pare it down.
      * I do really like the `ctrl+u` / `ctrl+e` / `ctrl+a` keybindings that it supports. That's a nice tough. But I don't need a
        lot of it.
    * DONE Is there a way to not leave the filtering input? I always want to be able to type and move down/up/enter. 
    * DONE Pare down DefaultFilter
    * DONE Pare down item interface stuff
    * (partially done) Pare down (inline) styles
* [x] DONE Re-use the `textinput` Bubbles component and in general compress the code 
* [ ] Re-size defect. When resizing and then moving the cursor, the program panics.
* [ ] Consider ranking "exact matches" before fuzzy matches? If I type "rea" I want to see "README.md" appear before
  "gradlew.bat".
* [x] DONE Support multi-line
* [ ] Support special (longer unicode?) characters like `°` in the underline highlighting.
* [ ] Defect: Cursor is not blinking at start.
