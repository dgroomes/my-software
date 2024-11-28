# java-body-omitter

Omit method bodies from Java code (so we can fit inside LLM context windows).


## Overview

This is the Java equivalent of the `go-body-omitter` program. Study that subproject for more information. 


## Instructions

1. Pre-requisite: Java 21, [Buf CLI](https://buf.build/product/cli) 
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
      do run --daemon
      ```
    * ```nushell
      'class Foo { void hello( ) { out.println("Hello"); } }' | do send
      ```
    * It should print the stripped Java code.
8. As needed, re-generate the Protobuf codegen
    * This program uses Protobuf to communicate to the caller when running in daemon mode. The Protobuf-generated Java
      classes are version controlled. If you update the `.proto` files, generate them again with the following command.
    * ```nushell
      do gen
      ```
9. Try the Protobuf mode
    * ```nushell
      'class Foo { void hello( ) { out.println("Hello"); } }' | do run --protobuf | buf convert ../../proto/java_body_omitter.proto --type Response --from -#format=binpb
      ```
    * It should print the stripped Java code.
10. Try both modes
    * ```nushell
      do run --daemon --protobuf
      ```
    * ```nushell
      'class Foo { void hello( ) { out.println("Hello"); } }' | do send | buf convert ../../proto/java_body_omitter.proto --type Response --from -#format=binpb
      ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

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
* [x] DONE I want to try Protobuf/Buf just for learning (this project is way too small to use that; because string in / string
  out works well). Maybe I can receive a string, and return a Protobuf message including the stripped snippet, plus
  maybe some other metadata? Or a success code, plus an optional error message?
   * DONE Protobuf IDL
   * DONE Buf CLI. In shell, create object from JSON into Protobuf and back again.
   * DONE Protobuf deps in the java program
   * DONE Implement. Take a `--protobuf` flag that returns data in Protobuf binary blobs instead of strings.
   * SKIP (I did manual validation, but might go for more real tests later) Test. Express an object in Java then serialize to Protobuf then deserialize?
   * DONE (worked using `buf convert ../../proto/java_body_omitter.proto --type Response --from -#format=binpb`) On the input side, deserialize Protobuf binary into JSON
   * DONE (it worked without hassle. I'm still curious how delimiting works) Protobuf + daemon mode. Try this out. I'm confused about how to delimit messages.
* [ ] PARTIAL (I'm not actually getting any parallelism but can't tell if it's because of Nushell or my Java code) Parallelism. 
