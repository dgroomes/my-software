# my-config 

Personal configuration stuff including dot files, installation instructions and other configuration files.


## Overview

The most useful component of this repository is the [My macOS Setup](#my-macos-setup) section. It provides step-by-step
instructions I like to follow for setting up a new Mac.

The repo is organized in the following directories:


### `bash/`

My Bash config and notes about Bash auto-completion (I always forget how to set this up!).


### `iterm2/`

My iTerm2 config.

> iTerm2 is a terminal emulator for macOS that does amazing things.
> 
> -- <cite>https://iterm2.com</cite>


### `jetbrains/`

My configuration for JetBrains IDEs (e.g. Intellij and Android Studio).

> Essential tools for software developers and teams
> 
> <cite>https://www.jetbrains.com</cite>

See the README in [jetbrains/](jetbrains/).


### `karabiner/`

My configuration for the amazing tool *Karabiner-Elements* <https://github.com/tekezo/Karabiner-Elements>.

> Karabiner-Elements is a powerful utility for keyboard customization on macOS Sierra or later.
> 
> -- <cite>https://github.com/pqrs-org/Karabiner-Elements</cite>


### `navi/`

My [navi](https://github.com/denisidoro/navi) cheat sheets.

> An interactive cheatsheet tool for the command-line.
> 
> -- <cite>https://github.com/denisidoro/navi</cite>


### `starship/`

My config file for Starship.

> The minimal, blazing-fast, and infinitely customizable prompt for any shell!
>
> -- <cite>https://github.com/starship/starship</cite>


### `markdownlint/`

My configuration for `markdownlint` and `markdownlint-cli2`. 

> A Node.js style checker and lint tool for Markdown/CommonMark files.
> 
> -- <cite>https://github.com/DavidAnson/markdownlint</cite>

> A fast, flexible, configuration-based command-line interface for linting Markdown/CommonMark files with the markdownlint library
> 
> -- <cite>https://github.com/DavidAnson/markdownlint-cli2</cite>


## My macOS Setup

These are the instructions I follow when I get a new Mac or after I re-install macOS: 

1. Configure macOS system settings
    * `System Settings > Keyboard > Keyboard Shortcuts... > Modifier Keys` and configure "Caps Lock key" to perform "Control"
    * `System Settings > Keyboard > Keyboard Shortcuts... > Function Keys` and toggle on "Use F1, F2, etc. keys as standard function keys"
    * Consider changing the behavior of the function/globe key so that it doesn't annoyingly bring up the character picker even when I'm
      using the function key to do something like change the volume. See instructions in this [StackExchange answer](https://apple.stackexchange.com/a/419081/).
    * Remove clutter macOS app icons from the Dock. Remove an icon with the context menu item "Remove from Dock".
    * `System Settings > Desktop & Dock > Automatically hide and show the Dock`
    * `System Settings > Control Center > Clock Options > Display the time with seconds`
    * `System Settings > Control Center > Battery > Show percentage`
    * `System Settings > General > AirDrop & Handoff` and turn `AirPlay Receiver` off because [it uses port 500](https://developer.apple.com/forums/thread/682332).
2. Install Sublime Text
    * The `subl` command is convenient for launching Sublime Text and opening a specific file or directory. In a later
      setup step, my shell is configured so that `subl` is always available on the `PATH`. But for now, you can execute
      the following command to help you view/edit files during the bootstrap phase.
    * ```shell
      export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"
      ```
3. Install Xcode from the app store
    * Agree to the license (try to execute `git` in the terminal and it will prompt you to read the license and agree to it)
4. Install Rectangle <https://github.com/rxhanson/Rectangle> for fast and easy window resizing
    * Uncheck all keyboard shortcuts. Configure the following:
        * "Left Half": `Ctrl + [`
        * "Right Half": `Ctrl + ]`
        * "Maximize": `Ctrl + \`
5. Clone this repository
    * First make the "repos" directory with `mkdir -p ~/repos/personal`
    * `cd ~/repos/personal && git clone https://github.com/dgroomes/my-config.git`
    * Finally, move to this directory because many of the later setup steps assume you are in this directory because they use relatives paths: `cd my-config`
6. Install iTerm2 <https://iterm2.com/downloads.html>. Configure it with my configuration:
    * Create the iTerm config directory with  `mkdir -p ~/.config/iterm2`
    * Copy the plist file with `cp iterm2/com.googlecode.iterm2.plist ~/.config/iterm2/com.googlecode.iterm2.plist`
    * Open iTerm and navigate to `Preferences > General > Preferences`. Check `Load preferences from a custom folder or URL` and set it
      to `~/.config/iterm2`.
    * A prompt will come up to save the current settings. Do *not* save the current settings.
    * Check `Save changes to folder when iTerm2 quits`.
    * Restart iTerm
7. Install Homebrew <https://brew.sh/>
    * Make sure to install Homebrew in the Apple Silicon configuration. I won't repeat the details here, but basically,
      it should be installed at `/opt/homebrew` and not `/usr/local`.
8. Install Bash
    * macOS uses a years old version of Bash and will never update it because of licensing. We'll use HomeBrew to install a modern version of Bash.
      First, initialize the HomeBrew environment config with the following command (yes, this is awkward but the nature of bootstrapping systems is
      indeed awkward).
    * ```shell
      eval $(/opt/homebrew/bin/brew shellenv)
      ``` 
    * Next, install Bash with the following command.
    * ```shell
      brew install bash
      ```
    * After installing from Homebrew, you will need to change the default shell with the following:
    * ```shell
      sudo bash -c 'echo /opt/homebrew/bin/bash >> /etc/shells'
      ```
    * ```shell
      chsh -s /opt/homebrew/bin/bash
      ```
    * Open a new session and verify the new version of Bash is being used with the following command.
    * ```shell
      echo $BASH_VERSION
      ```
9. Configure my custom Bash setup
   * Install [bash/bashrc-bundler.pl](bash/bashrc-bundler.pl), known as `bb`, using the following commands.
   * ```shell
     sudo mkdir /usr/local/bin
     sudo ln -s "$PWD/bash/bashrc-bundler.pl" /usr/local/bin/bb
     ```
   * Copy over the `.bash_profile` to the home directory with the following command.
   * ```shell
     cp bash/.bash_profile ~
     ```
   * Copy over some base Bash scripts that are designed to be incorporated into your Bash environment via sourcing or via `bb`. Use the following commands.
   * ```shell
     mkdir -p ~/.config/bash
     cp bash/bash-env-early.bash ~/.config/bash
     cp bash/bash-aliases.bash ~/.config/bash
     cp bash/bash-functions.bash ~/.config/bash
     cp bash/bash-completion.bash ~/.config/bash
     ```
   * Generate a `.bashrc` file with `bb` using the following command.
   * ```shell
     bb
     ```
   * Open a new Bash session and enjoy the customizations of aliases, functions, etc. You will be using `bb` over time to re-generate 
     the `.bashrc` file to accommodate new tooling and your own customizations.
10. Install 'bash-completion'.
     * ```shell
       brew install bash-completion@2
       ```
     * See additional information in `bash/BASH_COMPLETION.md`.
     * Run the `bash/sync-homebrew-managed-bash-completions.pl` script whenever you install a HomeBrew package that comes with completion
       scripts. For more information, read the notes in that script.
11. Install [Atuin](https://github.com/atuinsh/atuin)
     * I'm in the "kicking the tires" phase with Atuin. It's been popular for a few years and is getting even more refined.
       I do have a lack-luster shell history development experience, so I'm interested to see what Atuin has to offer.
     * Atuin's Bash support requires that [Bash-Preexec](https://github.com/rcaloras/bash-preexec) is installed. Install
       Bash-Preexec with the following commands.
     * ```shell
       mkdir -p ~/.local/lib/bash-preexec
       curl https://raw.githubusercontent.com/rcaloras/bash-preexec/da64ad4b7bb965d19dbeb5bb7447f1a63e3de2e3/bash-preexec.sh > ~/.local/lib/bash-preexec/bash-preexec.sh
       ```
     * Install Atuin with the following command.
     * ```shell
       brew install atuin
       ```
     * Copy over my config, and generate Bash completions with the following commands.
     * ```shell
       mkdir -p ~/.config/atuin && cp atuin/config.toml ~/.config/atuin
       mkdir -p ~/.local/share/bash-completion/completions && atuin gen-completions --shell bash --out-dir ~/.local/share/bash-completion/completions
       ```
     * Finally, incorporate Bash-Preexec and Atuin into the bundler flow with the following command.
     * ```shell
       cp bash/bash-atuin-dynamic-late.bash ~/.config/bash
       bb
       ```
12. Install JetBrains Toolbox <https://www.jetbrains.com/toolbox-app/>
    * Open Toolbox
    * Log in to your JetBrains account
    * Install Intellij Ultimate
    * In `my-config`, build my JetBrains preferences file (`settings.zip`). See instructions in the root `README.md`
    * Open this project in Intellij from the command line with the following command.
    * ```shell
      idea .
      ```
    * Import settings from the `settings.zip` created earlier
    * Disable unneeded plugins (there are a lot!)
    * Install desired plugins (which ones do I like? JetBrains is pretty great about bundling and supporting tons already
      that I don't need many third-party ones).
    * In macOS settings, disable the "Cmd + Shift + A" system keyboard shortcut so it does not conflict with the
      "Find Action" Intellij keyboard shorcut. See instructions at <https://intellij-support.jetbrains.com/hc/en-us/articles/360005137400-Cmd-Shift-A-hotkey-opens-Terminal-with-apropos-search-instead-of-the-Find-Action-dialog>
13. Install `jq`
     * ```shell
       brew install jq
       ```
14. Install `kcat`
     * ```shell
       brew install kcat
       ```
15. Install Python 3 and do basic setup
     * Note: Consider installing manually or using something like HomeBrew. There are pros and cons to each approach.
       To install using HomeBrew, use the following command.
     * ```shell
       brew install python
       ```
16. Install Starship <https://github.com/starship/starship>
     * > The minimal, blazing-fast, and infinitely customizable prompt for any shell!
     * ```shell
       brew install starship
       ```
     * Incorporate the Starship initialization code to your `.bashrc`. Use the `[bash-starship-dynamic.bash](bash%2Fbash-starship-dynamic.bash)
       file and regenerate the `.bashrc` with `bb`.
     * For more information, read the official instructions in the [Starship README.md](https://github.com/starship/starship#-installation).
     * Do the fonts installation (Note that this uses [a neat feature of git](https://stackoverflow.com/a/52269934) that
       only downloads a specific directory of the repo). Choose "Keep Both" every time you are prompted.
       ```shell
       git clone \
         --depth 1  \
         --filter=blob:none  \
         --sparse \
         https://github.com/ryanoasis/nerd-fonts.git ~/repos/opensource/nerd-fonts
       pushd ~/repos/opensource/nerd-fonts
       git sparse-checkout set patched-fonts/FiraCode
       open patched-fonts/FiraCode/Bold/FiraCodeNerdFontMono-Bold.ttf
       open patched-fonts/FiraCode/Light/FiraCodeNerdFontMono-Light.ttf
       open patched-fonts/FiraCode/Medium/FiraCodeNerdFontMono-Medium.ttf
       open patched-fonts/FiraCode/Regular/FiraCodeNerdFontMono-Regular.ttf
       open patched-fonts/FiraCode/Retina/FiraCodeNerdFontMono-Retina.ttf
       open patched-fonts/FiraCode/SemiBold/FiraCodeNerdFontMono-SemiBold.ttf
       popd
       ```
     * Restart iTerm2, configure "Use a different font for non-ASCII text" and choose the just installed "FiraCode Nerd Font Mono" font to get the special symbols
     * Copy over the custom Starship config file with the following command.
     * ```shell
       mkdir -p ~/.config && cp starship/starship.toml ~/.config
       ```
17. Add `~/.inputrc`
     * `cp .inputrc ~`
18. Install Bash completions for `pip`
     * ```shell
       pip3 completion --bash > ~/.local/share/bash-completion/completions/pip3
       ```
     * Note: I haven't vetted this in 2023.
19. Install SDKMAN <https://sdkman.io/>
     * Remove the initialization snippet that the install script added to the `.bashrc`/`.bash_profile` and instead
       incorporate my own initialization script with the following command.
     * ```shell
       cp bash/bash-sdkman-late.bash ~/.config/bash/
       ```
     * Regenerate the `.bashrc` with `bb` using the following command.
     * ```shell
       bb
       ```
     * Install the latest LTS Java and perhaps older versions as needed and the latest Java if you want to explore its features.
     * Install the latest version of Gradle
     * Install the latest version of Maven
     * (Note: I haven't vetted this for 2023) Install `visualvm` and then configure visualvm to use the Java 8.
         * Follow the instructions at <https://gist.github.com/gavvvr/c9891684f9ef062502d58c80903be5cc>
         * Specifically, edit the file `~/.sdkman/candidates/visualvm/current/etc/visualvm.conf`
20. Install `fnm` (Fast Node Manager) <https://github.com/Schniz/fnm> and Node.js
     * > 🚀 Fast and simple Node.js version manager, built in Rust
     * ```shell
       brew install fnm
       ```
     * I noticed the shell completion that was installed isn't working (there is no effect when pressing tab) but I had
       success by installed completion with the following command.
     * ```shell
       fnm completions --shell bash > ~/.local/share/bash-completion/completions/fnm
       ```
     * Install the latest Long-Term Support (LTS) version of node with the following command.
     * ```shell
       fnm install --lts
       ```
     * Tip: learn about releases and support horizons for Node.js versions on the official [*Previous Releases* page](https://nodejs.org/en/about/previous-releases). 
     * Incorporate fnm initialization code using the "-dynamic" Bash file and then regenerate the `.bashrc` with `bb`.
       Use the following commands.
     * ```shell
       cp bash/bash-fnm-dynamic.bash ~/.config/bash/
       ```
     * Regenerate the `.bashrc` with `bb` using the following command.
     * ```shell
       bb
       ```
21. Install latest `git` and configure it
     * ```shell
       brew install git
       ```
     * Configure basic `git` config elements <https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup>
         * ```shell
           git config --global user.name "John Doe"
           ```
             * But change the name
         * ```shell
           git config --global user.email johndoe@example.com
           ```
             * But change the address
         * ```shell
           git config --global pull.ff only
           ```
             * When I pull, I don't want it to create a merge if I am behind the remote.
         * ```shell
           git config --global init.defaultBranch main
           ```
         * ```shell
           git config --global alias.lg "log --all --graph --pretty=format:'%C(green)%ad%C(reset) %C(auto)%h%d %s %C(blue)<%aN>%C(reset)' --date=format-local:'%Y-%m-%d'"
           ```
             * Create a cool alternative to `git log` named `git lg`
         * ```shell
           git config --global alias.st "status --short --branch"
           ```
         * ```shell
           git config --global core.editor "subl -n -w"
           ```
             * Use Sublime Text as the editor instead of Vim. This is for things things like git rebase and amend operations.
               See [this nice GitHub doc](https://docs.github.com/en/get-started/getting-started-with-git/associating-text-editors-with-git) about configuring external editors.
         * ```shell
           git config --global push.autoSetupRemote true
           ```
             * This makes it so that your first `git push` will work and you don't need `git push --set-upstream ...`.
     * Configure `git` credentials
         * Note: when it comes to learning and configuring Git credentials, I recommend you bias towards official Git
           mechanisms and not to the GitHub-specific advice which touts the GitHub CLI and something called Git Credential
           Manager (GCM) which is not a Git official project. Know your options.
         * Read the [*7.14 Git Tools - Credential Storage*](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)
           section of the *Git Book*.
         * ```shell
           git config --global credential.helper osxkeychain
           ```
         * The next time you `git push` you will get a popup. Enter a Personal Access Token (PAT) and choose "Always allow".
           When the PAT expires, I'm not 100% sure what the UX is. I think it just prompts for the username/password again
           and doesn't given an error message.
     * Create and configure a global [gitignore file](https://git-scm.com/docs/gitignore)
         * ```bash
           cat << EOF > "$HOME/.gitignore_global"
           .DS_Store
           EOF
           git config --global core.excludesfile "$HOME/.gitignore_global"
           ``` 
         * The exclusions described by a global gitignore file should be sparing for two reasons. 1) If a project is
           shared, it's convenient for everyone else if the exclusions are version-controlled in the project-specific
           gitignore file. 2) Projects are diverse and unpredictable. There might be a project that wants to version-control
           the `build/` or `out/` directories, and for good reason. For me, the `.DS_Store` exclusion is a very safe bet. 
22. Install Docker Desktop <https://docs.docker.com/desktop/install/mac-install/>
     * Then, install Bash completion for `docker` and `docker-compose` by following [the docs](https://docs.docker.com/desktop/faqs/macfaqs/#how-do-i-install-shell-completion). It boils down to:
       ```bash
       ln -s /Applications/Docker.app/Contents/Resources/etc/docker.bash-completion ~/.local/share/bash-completion/completions/docker
       ln -s /Applications/Docker.app/Contents/Resources/etc/docker-compose.bash-completion ~/.local/share/bash-completion/completions/docker-compose
       ```
     * Apply the Bash completion to the `d` alias (the alias was defined in the `bash-aliases.sh` script) with the
       following command.
     * ```bash
       cat << EOF > "$HOME/.local/share/bash-completion/completions/d"
           # This is a neat trick to apply Bash completion to an aliased version of a command.
           # You need to know the location of the Bash completion script and the exact 'complete ...' command that's
           # used to apply it. See https://unix.stackexchange.com/a/685829/215204
           source "$HOME/.local/share/bash-completion/completions/docker"
           complete -F _docker d
       EOF
       ```
     * Configure Docker to use fewer resources. Consider only 2-3 cores and 6GB (but it depends on the need and constraints).
23. Install Karabiner-Elements <https://github.com/pqrs-org/Karabiner-Elements> from source (or HomeBrew) and configure it with.
     1. First, we must configure Xcode command line tools correctly. Follow these instructions <https://stackoverflow.com/a/61725799>
     2. Then, install `xcodegen` from source <https://github.com/yonaskolb/XcodeGen>:
        ```shell
        git clone --depth 1 https://github.com/yonaskolb/XcodeGen.git ~/repos/opensource/XcodeGen
        cd ~/repos/opensource/XcodeGen/
        mkdir -p "$HOME/.local/share" "$HOME/.local/bin"
        make PREFIX="$HOME/.local" install
        ```
     3. ```shell
        brew install xz
        brew install cmake
        ```
     4. Then, install Karabiner Elements
        ```shell
        git clone --depth 1 https://github.com/pqrs-org/Karabiner-Elements.git ~/repos/opensource/Karabiner-Elements
        cd ~/repos/opensource/Karabiner-Elements
        git submodule update --init --recursive --depth 1
        make package
        ``` 
     5. Install from the `.dmg` file that was just created in the root of the project. E.g. `Karabiner-Elements-14.12.1.dmg`.
     6. Then, configure it with my custom settings
        ```shell
        mkdir -p ~/.config/karabiner/assets/complex_modifications
        cp karabiner/karabiner.json ~/.config/karabiner
        cp karabiner/assets/complex_modifications/* ~/.config/karabiner/assets/complex_modifications
        ```
24. Install Insomnia <https://insomnia.rest/download/>
25. Install Go <https://golang.org/dl/>
     * Note: Consider installing manually or using something like HomeBrew. There are pros and cons to each approach.
       To install using HomeBrew, use the following command.
     * ```shell
       brew install go
       ```
26. Install Bash completion for Gradle
     * `curl https://raw.githubusercontent.com/gradle/gradle-completion/7b084bd68c79be27b8200c7a25e6d00c9c65f9a9/gradle-completion.bash -o /usr/local/etc/bash_completion.d/gradle-completion.bash`
     * Apply the Bash completion to the `gw` alias (the alias was defined in the `bash-aliases.sh` script) with the
       following command.
     * ```bash
       cat << EOF > "$BASH_COMPLETION_COMPAT_DIR/gw"
           # This is a neat trick to apply Bash completion to an aliased version of a command.
           # You need to know the location of the Bash completion script and the exact 'complete ...' command that's
           # used to apply it. See https://unix.stackexchange.com/a/685829/215204
           source "$BASH_COMPLETION_COMPAT_DIR/gradle-completion.bash"
           complete -F _gradle gw
       EOF
       ```
27. Install `libpq` so we can get `psql`
     * Follow directions at <https://blog.timescale.com/tutorials/how-to-install-psql-on-mac-ubuntu-debian-windows/>
     * `brew install libpq`
     * `brew link --force libpq`
28. Build and install Apache JMeter, a load testing and performance measurement tool
     1. `git clone https://github.com/apache/jmeter`
     2. Build it with `./gradlew createDist`
     3. Add the `bin/` directory to the path.
         * For example, append something like `export PATH="$PATH:~/repos/opensource/jmeter/bin"` to your `.bashrc`
29. Install fzf <https://github.com/junegunn/fzf>
     1. Install it using the [HomeBrew option](https://github.com/junegunn/fzf/blob/20230402d087858ca9a93aa8fe53d289f29c1836/README.md?plain=1#L28)
     2. ```shell
        brew install fzf
        ```
     3. Enable fuzzy auto-completion and key bindings with the following command (for some reason I'm having trouble
        executing this command from Intellij's embedded terminal but I can't deal with this right now so just execute it
        from iTerm.
     4. ```shell
        $(brew --prefix)/opt/fzf/install
        ```
     5. When it prompts for *Do you want to enable fuzzy auto-completion?* Answer YES
     6. When it prompts for *Do you want to enable key bindings?* Answer YES
     7. When it prompts for *Do you want to update your shell configuration files?* Answer NO (instead we use the `bash/bash-fzf.bash` file)
30. Install `gh` https://github.com/cli/cli
     1. ```shell
        brew install gh
        ```
     2. Use it for the first time and log in.
     3. Generate a 'bash-completion' completion file and save it to a file. Use the following command.
     4. ```shell
        gh completion --shell bash > "$HOME/.local/share/bash-completion/completions/gh"
        ``` 
31. Install [navi](https://github.com/denisidoro/navi)
     1. ```shell
        brew install navi
        ```
     2. Copy over the config files.
        ```shell
        mkdir -p "$HOME/Library/Application Support/navi/cheats/mycheats"
        cp navi/*.cheat "$HOME/Library/Application Support/navi/cheats/mycheats"
        ```
32. Install MongoDB *Community Server*
     1. Download from <https://www.mongodb.com/try/download/community>.
     2. Extract and put somewhere on the PATH.
         * e.g. symlink it to `~/dev/mongodb` and then add to `.bashrc` the following: `export PATH="$PATH:~/dev/mongodb/bin"`
     3. Create a base directory that we will use by convention for the MongoDB data files and logs:
         * `sudo mkdir /usr/local/mongodb`
     4. Assign ownership to the normal user so that our convenience scripts defined in `bash/bash-functions.sh` will work
        without sudo.
         * `sudo chown -R $(whoami) /usr/local/mongodb`
     5. Also, download and install the [*The MongoDB Database Tools*](https://docs.mongodb.com/database-tools/installation/installation-macos/)
         * e.g. symlink it to `~/dev/mongodb-database-tools` and then add to `.bashrc` the following: `export PATH="$PATH:~/dev/mongodb-database-tools/bin"`
     6. Also, consider downloading and installing the beta (but pretty feature-ful and cool) *new* Mongo shell called `mongosh`
         * Download from the [GitHub Releases page for the project](https://github.com/mongodb-js/mongosh/releases)
         * e.g. symlink it to `~/dev/mongosh` and then add to `.bashrc` the following: `export PATH="$PATH:~/dev/mongosh/bin"`
33. Install Rust
     1. Install `rustup` using the instructions in the official [rust-lang site](https://www.rust-lang.org/tools/install)
     and **do not** allow it to modify the `PATH`.
     2. Install `rustup` and `cargo` Bash completions with the following commands.
     3. ```shell
        rustup completions bash > "$HOME/.local/share/bash-completion/completions/rustup"
        rustup completions bash cargo >> "$HOME/.local/share/bash-completion/completions/cargo"
        ```
34. Rust-based tools
     * There is a nascent but rich ecosystem of Rust-based command-line tools. Many of them are substitutes for traditional
       commands like `ls`, `du`, and `cat` but they bring a bevy of extra features. Best of all, they are fast. Keep track
       of this "re-implemented in Rust" trend and follow this great article [*Rewritten in Rust: Modern Alternatives of Command-Line Tools*](https://zaiste.net/posts/shell-commands-rust/)
       on <https://zaiste.net/>.
     * `eza` might be my favorite. Install it with the following command.
     * ```shell
       cargo install eza
       ```
     * `jless` is a CLI tool for helping you view JSON. Install it with the following command.
     * ```shell
       cargo install --git https://github.com/PaulJuliusMartinez/jless
       ```
35. Install and configure linting for Markdown
     1. Install [`markdownlint-cli2`](https://github.com/DavidAnson/markdownlint-cli2):
         * `npm install markdownlint-cli2 --global`
     2. Install [`markdownlint-cli2-formatter-pretty`](https://github.com/DavidAnson/markdownlint-cli2/tree/main/formatter-pretty)
         * `npm install markdownlint-cli2-formatter-pretty --global`
     3. Clone <https://github.com/dgroomes/markdownlint-playground>
     4. Build the `lint-rules/` package
         * `cd lint-rules; npm install -g`
     5. Use the alias `mdlint` to lint a file. See earlier instructions to configure Bash with this and other aliases.
36. Install the AWS CLI
     * Follow the [installation instructions in the AWS doc site](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
       I followed the GUI instructions.
37. Install the AWS Cloud Development Kit (CDK) CLI
     * Follow the [installation instructions in the AWS doc site](https://aws.amazon.com/getting-started/guides/setup-cdk/module-two/)
     * These are the commands I ran.
     * ```shell
       nvm install --lts
       ```
     * ```shell
       nvm use --lts
       ```  
    * ```shell
       npm install -g aws-cdk
       ```
38. Install [CleanShot](https://cleanshot.com/)
    * Enter the license key
    * Go through the configuration steps in the prompt.
39. Install Rosetta
    * ```shell
      softwareupdate --install-rosetta
      ```
    * I don't love that I have to do this (to support some rare binaries like Java gRPC codegen) because sometimes I might
      forget that I'm running a binary that is not native to the M1 chip. But, I'm doing it anyway.


## Wish List

General clean-ups, TODOs and things I wish to implement for this project

* [x] DONE System for measuring the time it takes to load scripts in `.bashrc` and `.bash_profile`. I want to do something
  like [this very cool project](https://github.com/colindean/hejmo/blob/0f14c6d00c653fcbb49236c4f2c2f64b267ffb3c/dotfiles/bash_profile#L93)!
* [x] DONE (The answer is: never use eager completionloading) Loading my bash completions is slow. Doesn't bash completions support lazy loading? I have some good notes in `bash/BASH_COMPLETION.md`.
  Maybe most software still only provides v1 completion (which doesn't support lazy/on-demand)...
* [x] DONE Create my personal framework/strategy for managing "scripts to source during Bash shell initialization time"
    * DONE Scaffold out a Perl script
* [ ] SKIP Add more external documentation to `bb` (the internal documentation in the '--help' is already extremely thorough)
* [ ] Implement the fifo/domain-socket -based benchmarking described in `bb`
