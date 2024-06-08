# homebrew

I'm trying out maintaining my own Homebrew tap in this repository (see the `Formula` directory). In particular, I'm
starting with a formula for OpenJDK, which is part of my strategy for getting smooth JDK management working in my
Nushell environment (because I can't just use SDKMAN because it's Bash/Zsh exclusive). Let's see what happens.

## OpenJDK

My OpenJDK formulas are authored by doing some manual work to figure out the latest versions of the Eclipse Temurin
distributions of OpenJDK. See the `adoptium.http` file to get started.
