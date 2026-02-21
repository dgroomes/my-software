# homebrew

Like many Mac users, I use Homebrew to manage packages. I'm also experimenting with maintaining my own Homebrew package
definitions (a.k.a. *formulas*) as a way to consolidate my management of other software. I want to use Homebrew as a
familiar interface for installations, upgrades and uninstallations. This repository acts as a Homebrew *tap*. Formulas
are in the `Formula/` directory.


## OpenJDK

In particular, I'm experimenting with formulas for OpenJDK which is part of my strategy for creating a smooth JDK
management workflow in my Nushell environment. I'm a longtime user of SDKMAN, but because it only works in Bash/Zsh I
need to figure something else out.

My OpenJDK formulas are authored by doing some manual work to figure out the latest versions of the Eclipse Temurin
distributions of OpenJDK, the links to download the binaries, and the checksums. I execute the HTTP requests in
`adoptium.http` to do this work.

One aspect of my OpenJDK formulas is that they do not build from source. If I understand correctly, well-behaved
Homebrew formulas typically build from source (or are bottles built from the same instructions). I'm veering from the
standard because I'm happy to download the Eclipse Temurin binaries instead of building from source.


## Reference

- [GitHub repository: *homebrew-playground*](https://github.com/dgroomes/homebrew-playground)
  * This is my own codebase for learning Homebrew
- [Adoptium](https://adoptium.net)
  * > Prebuilt OpenJDK Binaries for Free!
- [Homebrew core formula for OpenJDK 17](https://github.com/Homebrew/homebrew-core/blob/3f593a20333d496928a1daed45aedc8f1b2b454a/Formula/o/openjdk%4017.rb)
  * This was helpful to study as a reference for my own formulas.
