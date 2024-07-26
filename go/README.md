COMMITTING ONLY FOR POSTERITY. I don't have a need for this it turns out.

# go

Go code I've written for my own use: CLI tools, etc.  


## Overview

I made the choice to house my Go code in my `my-config` repository instead of having it in its own repository. While
it's often convenient to have a chunk of source code in its own repository,  I open this directory in the GoLand IDE. I might consider building and publishing these binaries using GitHub Actions,
and then installing them via HomeBrew, but for now, `go install` should work fine for me.


## Instructions

1. Build the `git-json` binary:
   * ```shell
     go build ./...
     ```
   * Try it out by running the binary in different directories, etc. If you are satisfied, then you can install it
     globally with the following command.
2. Build and install the binary to your `GOBIN`:
   * ```shell
     go install ./...
     ```
   * Now you can run `git-json` from anywhere in your terminal.
