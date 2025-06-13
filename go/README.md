# go

Go code that supports my personal workflows.


## Overview

To develop the Go code in this directory, I open this directory in the GoLand IDE. I won't bother trying to use Intellij
to develop Go. I've found, for example, that developing Python in Intellij is troublesome and I prefer to use PyCharm.
Same story for Android development, just use Android Studio.

Note: I might consider building and publishing binaries using GitHub Actions, and then installing them via Homebrew, but
for now, `go install` should work fine for me.


## `my-java-launcher`

`my-java-launcher` is a launcher for Java programs.

An advantage of a launcher is that you run a program with only one word instead of multiple. For example, launching a Java program normally looks something like this:

```shell
java -cp my-program.jar com.example.MyProgram
```

Whereas with a launcher, the details are encapsulated:

```shell
my-program
```

A compressed form like this is useful, for example, if you want to use the program as a CLI tool. Having a launcher makes a Java program much more "installed" compared to just having a `.jar` file.

`my-java-launcher` is designed to be shipped in the program's installation directory, side-by-side the program's `.jar` files and related program assets. `my-java-launcher`, will find and invoke a specified version of Java installed on the system. It depends on a `my-manifest.json` file that describes the exact version of Java, the classpath, the main class, and other Java system properties, etc.

This is an alternative to the Gradle [`application` plugin](https://docs.gradle.org/current/userguide/application_plugin.html) which creates a shell *start script* that encodes all this same info. I use the `application` plugin very frequently, but now, I need to eject from Posix shell and get finer control and better legibility. So I'm going with a "Go binary + JSON manifest" as a Java program launcher.


## `my-node-launcher`

`my-node-launcher` launches Node.js programs by finding and invoking a specified version of Node.js installed on the system. Similar to `my-launcher`, it uses a manifest file(`my-node-launcher.json`) that describes the required Node.js version and an entrypoint JavaScript file.


## `my-fuzzy-finder`

`my-fuzzy-finder` is a commandline fuzzy finder with a JSON API. It's designed to have a similar user experience to
`fzf`.

I think `fzf` really got the UX right, and it's been replicated in many tools. The main feature I'm missing from `fzf`
is the ability to have structured input and output. I use [Nushell](https://www.nushell.sh/) which is a shell that uses
structured data, and the more that my tools can support structured data, the better.

When it comes to matching on [multi-line items in `fzf`, you can do it](https://junegunn.github.io/fzf/tips/processing-multi-line-items/),
but you have to ditch the familiar newline-delimited model and instead use a `NUL`-delimited model. Some tools support
this out-of-the-box, like `find`, which has the `-print0` option. But for many other tools, you have to retrofit their
output with some scripting. For me, I can afford to shape my tools to use structured data instead of injecting this
structure in an ad-hoc way. I want to avoid particularly gnarly stringly-typed programming.

`my-fuzzy-finder` is a TUI (text user interface) program built using these excellent projects:

- The [Bubble Tea](https://github.com/charmbracelet/bubbletea) TUI framework
- The [Bubbles](https://github.com/charmbracelet/bubbles) TUI component library
- The "fuzzy" library <https://github.com/sahilm/fuzzy>.


## `claude-sandboxed`

Launch Claude Code in a sandbox where network and file system access is restricted. 

When I work with Claude Code, I'm in a session on a particular directory and working on some specific task. We want the Claude session sandboxed to that directory and to a minimum set of external files and resources (files, environment variables, ports, etc).

My current thinking is to use the macOS seatbelt system to sandbox the process, and to use my `claude-proxy` server to constrain outbound network traffic. Go is a great choice for a launcher. In the launcher, we also run some pre-checks to assert that the environment is setup and provide actionable error messages if not.

Sandboxing reduces freedom, which means it will be annoying at times. Let's try to offset this annoyance by making the sandbox strategy clear and the launching process fast and clear as well.

In the future, I might consider:

* Use App Sandbox (unlikely because it does not work well for CLI tools)
* Use a container/VM (eyes are on the new "containers" project just released at WWDC 2025)
* Create a system for parameterizing allowed hosts, allowed executables, allowed dirs/files, and allowed environment variables.
* Genericize the launcher for other commandline agents or tools
* How to let Claude Code check for updates. Right now it makes a request to the npm registry. Should allow this endpoint flow?
* Allow passthrough of args from the launcher to Claude Code. As is, we've broken all the '-p' stuff and everything.
* Clean up these logs : ✅ Proxy server running  Sandbox applied. Running checks...  Unsolicited response received on idle HTTP channel starting with "Denied. This is a sandbox."; err=<nil> Unsolicited response received on idle HTTP channel starting with "Denied. This is a sandbox."; err=<nil>
* ... or maybe I'll do nothing because Claude Code might solve these things in later releases and/or a new alternative will emerge
 
The ideal user experience for launching Claude Code via the sandboxed launcher is:

```text
$ cs
✅ Proxy server running
Sandbox applied. Running checks...
✅ Remote calls blocked
✅ Anthropic calls via proxy allowed
✅ Non-Anthropic calls via proxy blocked

╭─────────────────────────────────────────────────╮
│ ✻ Welcome to Claude Code!
```


## Instructions

Follow these instructions to build, run and install my software.

1. Activate the Nushell `do` module
    * ```nushell
      do activate
      ```
2. Build and test the code:
    * ```nushell
      do test
      ```
3. Build and run the `my-fuzzy-finder` program with the example data:
    * ```nushell
      do run my-fuzzy-finder --example
      ```
    * Next, try fuzzy finding among the filenames in the current directory.
    * ```nushell
      ls | get name | str join (char newline) | do run my-fuzzy-finder
      ```
    * The output will be the selected filename.
    * Next, try a similar thing but with the JSON API. This takes a JSON array in and sends JSON out. The advantage of
      using a JSON array for input is that the items can have multiple lines, whereas in the typical newline-delimited
      input, your items can only be exactly one line.
    * ```nushell
      ["Hello, world!" "Dear reader,
      Hello.
      Sincerely, writer"] | to json | do run my-fuzzy-finder --json-in --json-out
      ```
    * It will output the selected filename but also the index of that item in the input list. It will look something
      like the following.
    * ```json
      {"index": 1, "item": "Dear reader,\nHello.\nSincerely, writer"}
      ```
    * Finally, try the program and enable debugging. The logs are printed to a local `my-fuzzy-finder.log` file.
    * ```nushell
      do run my-fuzzy-finder --example --debug
      ```
4. Build all executables:
    * ```nushell
      do build
      ```
    * The executables will be in the `bin/` directory. Try them out as needed to do validation and exploration. If you are satisfied, then you can install the executables globally with the next step.
5. Build and install the executables to your `GOBIN`:
    * ```nushell
      do install
      ```
    * Now you can run the executables from anywhere on your system.
6. Demonstrate `my-node-launcher`
    * Copy the launcher into the example JS app.
    * ```nushell
      cp bin/my-node-launcher example-js-app/capitalize
      ```
    * Try out the launcher. Launch the example program with the following command.
    * ```nushell
      ./example-js-app/capitalize hello world
      ```
    * It should output the following.
    * ```text
      Hello World
      ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [ ] Need to handle items that exceed the full height?
* [ ] Workaround `./` parsing gap of the new Nushell parser.
* [ ] Consider supporting env vars in the manifest files of the launchers. For now, YAGNI. But it can be useful for setting things like JVM memory options, etc.
* [ ] Flesh out `claude.sb`. I need to perfect the SBPL and get more narrow about allowed sub-process executables.
