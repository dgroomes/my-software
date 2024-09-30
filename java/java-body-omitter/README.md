# java-body-omitter

Omit method bodies from Java code (so we can fit inside LLM context windows).


## Overview

This is the Java equivalent of the `go-body-omitter` program. Study that subproject for more information. 


## Instructions

1. Pre-requisite: Java 21
2. Activate the Nushell overlay
    * ```nushell
      do activate
      ```
3. Run the tests
    * ```nushell
      do test
      ```
4. Build the program distributions
    * ```nushell
      do build
      ```
5. Try it out
    * ```nushell
      r#'
      class Foo {
      
          /**
           * Comments should be preserved.
           */
          void hello() {
              out.println("Hello");
          }
      }
      '# | do run
      ```
    * The output will be the following.
    * ```java
      class Foo {
      
          /**
           * Comments should be preserved.
           */
          void hello() {
              // OMITTED
          }
      }
      ```
6. Install the program distribution with a symlink
    * ```nushell
      do install
      ```
7. Now try the daemon mode
    * ```nushell
      do run-daemon
      ```
    * ```nushell
      'class Foo { void hello( ) { out.println("Hello"); } }' | do send
      ```
    * It should print the stripped Java code.


## Wish List

General clean-ups, TODOs and things I wish to implement for this project

* [x] DONE Scaffold. Thanks o1-preview (awesome in many ways; fails in surprising ways)
* [ ] The 'omitted' comment isn't actually included.
* [ ] Homebrew install
* [ ] Consider a Kotlin body omitter. Would this just be a superset of java-body-omitter because a Kotlin parsing
  library must already tolerate Java right? I guess most libraries are Java, so I might not do this. But if it's easy I
  want to do it.
* [x] DONE Test cases. This will help me a go little faster because I especially want to run with breakpoints and just
  discover the javaparser API. 
* [x] DONE Create a 'daemon' mode. The program can be run with the '--daemon' flag, and it will accept snippets
  of Java code on a Unix domain socket. This is good because we can amortize the cost of starting the JVM, which is very
  expensive compared to the cost of parsing a single Java snippet. THIS DOES NOT WORK. Please help.
* [ ] I want to try Protobuf/Buf just for learning (this project is way too small to use that; because string in / string
  out works well). Maybe I can receive a string, and return a Protobuf message including the stripped snippet, plus
  maybe some other metadata? Or a success code, plus an optional error message?
