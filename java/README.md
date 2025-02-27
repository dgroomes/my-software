# java

Java and Kotlin code that supports my personal workflows.


## Overview

In general, I'm having good success using Nushell for my personal utilities. But the commandline experience draws its
power from the many CLI tools that you use to actually do work. In this `java/` directory, I might make some Java/Kotlin
programs that are meant to be called from Nushell. I don't need to actually enrich these programs with manual pages,
flags, or anything typical of a CLI. Instead, I want these programs to just return JSON. I might wrap them in Nushell
commands that do command completion things, etc.

The strategy is:

* Nushell for CLIs
* Nushell for workflows
* A JSON-emitting program in Java, Go, etc. for non-trivial technical work that is implemented by open source libraries
