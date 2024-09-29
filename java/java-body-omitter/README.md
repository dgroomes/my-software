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
3. Build the program distributions
    * ```nushell
      do install
      ```
4. Try it out
    * ```nushell
      r#'
      public class Main {
      
          /**
           * Comments should be preserved.
           */
          public static void main(String[] args) {
              System.out.println("Hello, world!");
          }
      }
      '# | do run
      ```
    * The output will be the following.
    * ```java
      public class Main {
      
          /**
           * Comments should be preserved.
           */
          public static void main(String[] args) {
              // OMITTED
          }
      }
      ```
5. Install the program distribution with a symlink
    * ```nushell
      do install
      ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project

* [x] DONE Scaffold. Thanks o1-preview (awesome in many ways; fails in surprising ways)
* [ ] The 'omitted' comment isn't actually included.
* [ ] Homebrew install
* [ ] Consider a Kotlin body omitter. Would this just be a superset of java-body-omitter because a Kotlin parsing
  library must already tolerate Java right? I guess most libraries are Java, so I might not do this. But if it's easy I
  want to do it.
* [ ] Test cases. This will help me a go little faster because I especially want to run with breakpoints and just
  discover the javaparser API. 
