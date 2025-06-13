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
* [x] DONE Make a Node launcher for JavaScript programs. This would be similar to `my-java-launcher` but for Node.js. I don't see a compelling reason to couple a Node launcher with
  the Java launcher, especially because of the schema, there would be conflicting possible options like specifying a
  Java classpath while also specifying a Node version. Those don't go together. In the day and age of quick,
  context-window-amenable programs tailored for LLM copilot, small/focused is good.
   * DONE I need to advertise Node homes in an environment variable. What's a conventional name for this? In Java we use
     `JAVA_HOME`.
   * DONE Implement
* [ ] Consider supporting env vars in the manifest files of the launchers. For now, YAGNI. But it can be useful for setting things like JVM memory options, etc.
* [ ] Flesh out `claude.sb`. I need to perfect the SBPL and get more narrow about allowed sub-process executables.


## Finished Wish List Items

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
* [x] DONE (fixed/obsoleted by other refactoring) Re-size defect. When resizing and then moving the cursor, the program panics.
* [x] DONE Support multi-line
* [x] OBSOLETE (Somehow resolved on itself. Not sure why) Support special (longer Unicode?) characters like `°` in the underline highlighting.
* [x] DONE Defect: Get cursor blinking working again.
* [x] DONE Support JSON array input
* [X] DONE (Big restructuring but great result) Defect: beginning content is cut off. I think it's cutting off by as many additional lines there are per item
  beyond the first line. So a 2-line item will because 1 line to be cut off. The 'Filter: ' text input is missing, for
  example.
* [x] OBSOLETE (Already works, the content is just truncated, that's good) items that exceed the full width
* [x] DONE Support 'fzf' search syntax.
* [x] DONE (Update 2: I'm going to pare it down. A hard fork. Update 1: Alternatively, it might be best to just do a shallow fork so that I can preserve the diff better. Not sure.) Pare down 'fzf' code. Thankfully I was able to get fzf integration without many (half?) of the original source
  code. But still, I should be able to trim it down much more (and learn it).
    * DONE Remove caching
    * DONE consolidate item.go
    * More ...
* [x] DONE Case-insensitive
* [x] DONE Split into `my-fuzzy-finder-lib/` and `my-fuzzy-finder/` packages
* [x] DONE Tests.
* [x] SKIP (Update: well I don't want to deal with multiple outputs) Yeah I think I'd like this, just to be able to test, especially for more complex expressions) Consider supporting headless mode. But really, `fzf` should be fine for that.
* [x] DONE Support/fix the logical OR operator
* [x] DONE Can the algo be agnostic of case sensitivity?
* [x] DONE What's up with whitespace handling?
* [x] DONE Less pre-slicing
* [x] PARTIAL (Unfortunately the new Nushell parser is missing a critical mass of cases) posix-nushell-compatibility-checker. For prototypical commands (command plus string args) I don't want the
  noise of the Nu raw string. Just allow the original command to exist. 
   * DONE Scaffold.
   * DONE (IDK I think they are just there and that's fine) What are the top-level `*syntax.File` and `syntax.Stmt` types? Are those just always there?
   * I really need to parse Nushell as well. Because what looks like a string literal in shell could be interpolation
     in Nushell for example. I need to parse the expression for both langs (shell/Nu) and assert that they are both
     "boring cmd + string args". I don't need to support any more cases. This is better than 80/20, this is like 95/5.
   * DONE Scaffold a Rust program that uses the Nu parser.
   * DONE Call the Rust program from the Go program.
   * DONE Parse the output of the Rust program (just JSON into a map)
   * DONE Match the expressions (shell/Nu) for compatibility. This should be driven by tests, because it's subtle and maybe
     wide.
* [x] DONE `go-body-omitter`
   * DONE generate a first pass (o1-preview did a great job)
   * SKIP (fine enough for now) Study the generated code. Consider changes/comments/restructuring. Should we omit in a more nuanced way?
* [ ] SKIP (no, I'm not doing any scoring/bonus at all) Consider ranking "exact matches" before fuzzy matches? If I type "rea" I want to see "README.md" appear before
  "gradlew.bat".
