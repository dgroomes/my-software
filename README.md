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

1. Set up the keyboard (if using a Windows keyboard)
    * Open `System Preference > Keyboard >  Modifier Keys`
    * Select the keyboard from the `Select keyboard` dropdown
    * Map the following:
        * "Caps lock" to "Control"
        * "Command" to "Option" (if on an external Windows keyboard)
        * "Option" to "Command" (if on an external Windows keyboard)
    * "Use F keys as F keys"
    * (I think only applicable on some models, like the Macbook Air) Change the behavior of the function/globe key so that it
      doesn't annoyingly bring up the character picker even when I'm using the function key to do something like change the volume.
      See instructions in this [StackExchange answer](https://apple.stackexchange.com/a/419081/).
2. Install Xcode from the app store
    * Agree to the license (try to execute `git` in the terminal and it will prompt you to read the license and agree to it)
3. Install Rectangle <https://github.com/rxhanson/Rectangle> for fast and easy window resizing
    * Uncheck all keyboard shortcuts. Configure the following:
        * "Left Half": `Ctrl + [`
        * "Right Half": `Ctrl + ]`
        * "Maximize": `Ctrl + \`
4. macOS System Preferences
    * `Dock & Menu Bar > Automatically hide and show the Dock`
    * `Dock & Menu Bar > Clock > Show date` and `Show the day of the week`
    * `Dock & Menu Bar > Battery > Show percentage`
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
7. Install JetBrains Toolbox <https://www.jetbrains.com/toolbox-app/>
    * Open Toolbox
    * Log in to your JetBrains account
    * Install Intellij Ultimate
    * In `my-config`, build my JetBrains preferences file (`settings.zip`). See instructions in the root `README.md`
    * Open Intellij
    * Import settings from the `settings.zip` created earlier
    * Disable unneeded plugins
    * Enable shell integration. Go to the Toolbox App Settings in the top right corner (click the hexagon), expand "Shell Scripts", enable the toggle, and set the location to `/usr/local/bin`
    * Open Intellij from the command line with `idea .`
    * Enable "Use non-modal commit interface". See <https://www.jetbrains.com/help/idea/managing-changelists.html>
      Can I save this in my Intellij preferences?
    * In macOS settings, disable the "Cmd + Shift + A" system keyboard shortcut so it does not conflict with the
      "Find Action" Intellij keyboard shorcut. See instructions at <https://intellij-support.jetbrains.com/hc/en-us/articles/360005137400-Cmd-Shift-A-hotkey-opens-Terminal-with-apropos-search-instead-of-the-Find-Action-dialog>
8. Install Homebrew <https://brew.sh/>
    * Make sure to install Homebrew in the Apple Silicon configuration. I won't repeat the details here, but basically,
      it should be installed at `/opt/homebrew` and not `/usr/local`. 
9. `brew install bash`
    * macOS uses a years old version of Bash and will never update it because of licensing
    * After installing from Homebrew, you will need to change the default shell with the following.:
    * ```shell
      sudo bash -c 'echo /opt/homebrew/bin/bash >> /etc/shells'
      ```
    * ```shell
      chsh -s /opt/homebrew/bin/bash
      ```
    * Open a new session and verify the new version of Bash is being used `echo $BASH_VERSION`
    * Copy over the `.bash_profile` to the home directory with: `cp bash/.bash_profile ~`
    * Create a `.bashrc` with `touch ~/.bashrc`
    * Add colors to Bash. Add the following to `~/.bashrc`: `export CLICOLOR=1`
10. Install bash completion.
     * ```shell
       brew install bash-completion@2
       ```
     * See additional information in `bash/BASH_COMPLETION.md`. 
11. Configure a base setup for "sourcing into Bash"
     * The `.bash_profile` is the home base for configuring your shell just the way you like it.
     * Copy the contents of `bash/.bash_profile` to your own `.bash_profile`. Or, if you don't have anything there of
       your own, just replace the whole file.
     * Copy over some base Bash scripts that are designed to be sourced by `.bash_profile`. Use the following commands.
     * ```shell
       mkdir -p ~/.config/bash
       cp bash/bash-aliases.bash ~/.config/bash
       cp bash/bash-functions.bash ~/.config/bash
       cp bash/bash-completion.bash ~/.config/bash
       cp bash/bash-fzf.bash ~/.config/bash
       cp bash/bash-fzf.bash ~/.config/bash
       ```
12. ```shell
    brew install jq
    ```
13. `brew install kcat`
14. Install Python 3 and do basic setup
     * Download and install following the instructions on the official site: <https://www.python.org/downloads/>.
     * `sudo pip3 install --upgrade pip`
     * Add user-installed Python packages to the `PATH` by adding this line in `.bashrc`: `export PATH="$PATH:/Users/davidgroomes/Library/Python/3.9/bin"`
15. Install Starship <https://github.com/starship/starship>
     * > The minimal, blazing-fast, and infinitely customizable prompt for any shell!
     * ```shell
       brew install starship
       ```
     * Add the initialization code to your `.bashrc`. Follow the instructions in the [Starship README.md](https://github.com/starship/starship#-installation).
       Specifically, add:
       ```
       # Starship
       # https://github.com/starship/starship
       eval "$(starship init bash)"
       ```
     * Do the fonts installation (Note that this uses [a neat feature of git](https://stackoverflow.com/a/52269934) that
       only downloads a specific directory of the repo):
       ```
       git clone \
         --depth 1  \
         --filter=blob:none  \
         --sparse \
         https://github.com/ryanoasis/nerd-fonts.git ~/repos/opensource/nerd-fonts
       pushd ~/repos/opensource/nerd-fonts
       git sparse-checkout set patched-fonts/FiraCode
       open patched-fonts/FiraCode/Bold/complete/Fira\ Code\ Bold\ Nerd\ Font\ Complete\ Mono.ttf
       open patched-fonts/FiraCode/Light/complete/Fira\ Code\ Light\ Nerd\ Font\ Complete\ Mono.ttf
       open patched-fonts/FiraCode/Medium/complete/Fira\ Code\ Medium\ Nerd\ Font\ Complete\ Mono.ttf
       open patched-fonts/FiraCode/Regular/complete/Fira\ Code\ Regular\ Nerd\ Font\ Complete\ Mono.ttf
       open patched-fonts/FiraCode/Retina/complete/Fira\ Code\ Retina\ Nerd\ Font\ Complete\ Mono.ttf
       open patched-fonts/FiraCode/SemiBold/complete/Fira\ Code\ SemiBold\ Nerd\ Font\ Complete\ Mono.ttf
       popd
       ```
     * Restart iTerm2, configure "Use a different font for non-ASCII text" and choose the just installed "FiraCode Nerd Font Mono" font to get the special symbols
     * Copy over the custom Starship config file:
         * `mkdir -p ~/.config && cp starship/starship.toml ~/.config`
16. Add `~/.inputrc`
     * `cp .inputrc ~`
17. Install bash completion for `pip`: `pip3 completion --bash > /usr/local/etc/bash_completion.d/pip`
18. Install SDKMAN <https://sdkman.io/>
     * Install the latest LTS Java and perhaps older versions as needed and the latest Java if you want to explore its features.
     * Install the latest version of Gradle
     * Install the latest version of Maven
     * Install `visualvm` and then configure visualvm to use the Java 8.
         * Follow the instructions at <https://gist.github.com/gavvvr/c9891684f9ef062502d58c80903be5cc>
         * Specifically, edit the file `~/.sdkman/candidates/visualvm/current/etc/visualvm.conf`
19. Install `nvm` Node Version Manager <https://github.com/nvm-sh/nvm> and Node.js
     * Install the latest Long-Term Support version of node with `nvm install --lts`
     * Install npm completion with `npm completion > /usr/local/etc/bash_completion.d/npm`
     * Install a community-provided Bash completion script for npx with `curl https://gist.githubusercontent.com/gibatronic/44073260ffdcbd122e9520756c8e35a1/raw/54cacab82b57ce965cf9f69edcd3477d81e1fa58/complete_npx -o /usr/local/etc/bash_completion.d/npx`
20. Enable "Tab Hover Cards" in Chrome
     * Open `chrome://flags/` in Chrome
     * Set "Tab Hover Cards" to enabled
     * Set "Tab Hover Card Images" to enabled
     * Tab Hover Cards make it faster to preview the title of a tab
21. Install latest `git` and configure it
     * `brew install git`
     * Configure basic `git` config elements <https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup>
         * `git config --global user.name "John Doe"`
             * But change the name
         * `git config --global user.email johndoe@example.com`
             * But change the address
         * `git config --global pull.ff only`
             * When I pull, I don't want it to create a merge if I am behind the remote.
         * `git config --global init.defaultBranch main`
         * `git config --global alias.lg "log --all --graph --pretty=format:'%C(green)%ad%C(reset) %C(auto)%h%d %s %C(blue)<%aN>%C(reset)' --date=format-local:'%Y-%m-%d'"`
             * Create a cool alternative to `git log` named `git lg`
         * `git config --global alias.st "status --short --branch"`
         * `git config --global core.editor "subl -n -w"`
             * Use Sublime Text as the editor instead of Vim. This is for things things like git rebase and amend operations.
               See [this nice GitHub doc](https://docs.github.com/en/get-started/getting-started-with-git/associating-text-editors-with-git) about configuring external editors.
         * `git config --global push.autoSetupRemote true`
             * This makes it so that your first `git push` will work and you don't need `git push --set-upstream ...`.
     * Configure `git` credentials to Github. Follow <https://help.github.com/en/github/authenticating-to-github/accessing-github-using-two-factor-authentication#using-two-factor-authentication-with-the-command-line>
     * Use credentials helper <https://help.github.com/en/github/using-git/caching-your-github-password-in-git>
         * `git config --global credential.helper osxkeychain`
         * The next time you `git push` you will get a popup. Enter your password and choose "Always allow"
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
22. Install Docker Desktop <https://hub.docker.com/editions/community/docker-ce-desktop-mac/>
     * Then, install Bash completion for `docker` and `docker-compose` by following [the docs](https://docs.docker.com/desktop/faqs/macfaqs/#how-do-i-install-shell-completion). It boils down to:
       ```bash
       ln -s /Applications/Docker.app/Contents/Resources/etc/docker.bash-completion /usr/local/etc/bash_completion.d/docker
       ln -s /Applications/Docker.app/Contents/Resources/etc/docker-compose.bash-completion /usr/local/etc/bash_completion.d/docker-compose
       ```
     * Apply the Bash completion to the `d` alias (the alias was defined in the `bash-aliases.sh` script) with the
       following command.
     * ```bash
       cat << EOF > "$BASH_COMPLETION_COMPAT_DIR/d"
           # This is a neat trick to apply Bash completion to an aliased version of a command.
           # You need to know the location of the Bash completion script and the exact 'complete ...' command that's
           # used to apply it. See https://unix.stackexchange.com/a/685829/215204
           source "$BASH_COMPLETION_COMPAT_DIR/docker"
           complete -F _docker d
       EOF
       ```
     * Add to `~/.config/bash/bash-env.sh`: `export DOCKER_SCAN_SUGGEST=false` to disable the "Use 'docker scan'" message
       on every build. For reference, see [this GitHub issue discussion](https://github.com/docker/scan-cli-plugin/issues/149#issuecomment-823969364).
23. Install Karabiner-Elements from source <https://github.com/pqrs-org/Karabiner-Elements> and configure it with.
     1. First, we must configure Xcode command line tools correctly. Follow these instructions <https://stackoverflow.com/a/61725799>
     1. Then, install `xcodegen` from source <https://github.com/yonaskolb/XcodeGen>:
        ```
        git clone --depth 1 https://github.com/yonaskolb/XcodeGen.git
        cd XcodeGen
        make install
        ```
     1. ```
        brew install xz
        brew install cmake
        ```
     1. Then, install Karabiner Elements
        ```
        git clone --depth 1 https://github.com/pqrs-org/Karabiner-Elements.git
        cd Karabiner-Elements
        git submodule update --init --recursive --depth 1
        make package
        ``` 
     1. Then, configure it with my custom settings
        ```
        mkdir -p ~/.config/karabiner/assets/complex_modifications
        cp karabiner/karabiner.json ~/.config/karabiner
        cp karabiner/assets/complex_modifications/* ~/.config/karabiner/assets/complex_modifications
        ```
24. Install Insomnia <https://insomnia.rest/download/>
25. Install Go <https://golang.org/dl/>
     * Create the go home dir `mkdir -p ~/repos/go`
     * Make a best attempt at configuring the Go environment variables (
       reference <https://stackoverflow.com/questions/7970390/what-should-be-the-values-of-gopath-and-goroot>)
         * Add to `~/.bashrc`: `export GOPATH="$HOME/repos/go"`
         * Add to `~/.bashrc`: `export PATH="$PATH:$GOPATH/bin"`
     * Download and install Bash completion for `go` from <https://github.com/posener/complete/tree/master> (You might
       notice that the default branch is "v1" but this is only for legacy reasons. Read the project's README for more
       info.)
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
     1. Build it with `./gradlew createDist`
     1. Add the `bin/` directory to the path.
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
     1. `brew install gh`
     1. Use it for the first time and log in.
31. Clone `gradle-wrapper-upgrader`
     1. `git clone https://github.com/dgroomes/gradle-wrapper-upgrader.git`
     1. Add it to the PATH
32. Install [navi](https://github.com/denisidoro/navi)
     1. ```shell
        brew install navi
        ```
     2. Copy of the config files.
        ```shell
        mkdir -p "$HOME/Library/Application Support/navi/cheats/mycheats"
        cp navi/*.cheat "$HOME/Library/Application Support/navi/cheats/mycheats"
        ```
33. `git clone --depth 1 https://github.com/vsch/idea-multimarkdown`
34. Install MongoDB *Community Server*
     1. Download from <https://www.mongodb.com/try/download/community>.
     1. Extract and put somewhere on the PATH.
         * e.g. symlink it to `~/dev/mongodb` and then add to `.bashrc` the following: `export PATH="$PATH:~/dev/mongodb/bin"`
     1. Create a base directory that we will use by convention for the MongoDB data files and logs:
         * `sudo mkdir /usr/local/mongodb`
     1. Assign ownership to the normal user so that our convenience scripts defined in `bash/bash-functions.sh` will work
        without sudo.
         * `sudo chown -R $(whoami) /usr/local/mongodb`
     1. Also, download and install the [*The MongoDB Database Tools*](https://docs.mongodb.com/database-tools/installation/installation-macos/)
         * e.g. symlink it to `~/dev/mongodb-database-tools` and then add to `.bashrc` the following: `export PATH="$PATH:~/dev/mongodb-database-tools/bin"`
     1. Also, consider downloading and installing the beta (but pretty feature-ful and cool) *new* Mongo shell called `mongosh`
         * Download from the [GitHub Releases page for the project](https://github.com/mongodb-js/mongosh/releases)
         * e.g. symlink it to `~/dev/mongosh` and then add to `.bashrc` the following: `export PATH="$PATH:~/dev/mongosh/bin"`
35. Install Rust
     1. Install `rustup` using the instructions in the official [rust-lang site](https://www.rust-lang.org/tools/install).
     1. Add to `~/.config/bash/bash-env.sh`: `source ~/.cargo/env"`
         * This is a slightly clever way to configure the `PATH`. It comes installed with Rust so let's use it (idiomatic).
     1. Install `rustup` Bash autocompletion:
         * `rustup completions bash > "$BASH_COMPLETION_COMPAT_DIR/rustup"`
     1. Install `cargo` Bash autocompletion:
         * Note: the official Rust installation uses different mechanisms for Bash completion between `rustup`, `cargo`, etc.
           Keep an eye out for if/when this improves some day (fingers crossed!).
         * Add to `~/.config/bash/bash-env.sh`: `source "$(rustc --print sysroot)/etc/bash_completion.d/cargo"`
36. Rust-based tools
     * There is a nascent but rich eco-system of Rust-based command-line tools. Many of them are substitutes for traditional
       commands like `ls`, `du`, and `cat` but they bring a bevy of extra features. Best of all, they are fast. Keep track
       of this "re-implemented in Rust" trend and follow this great article [*Rewritten in Rust: Modern Alternatives of Command-Line Tools*](https://zaiste.net/posts/shell-commands-rust/)
       on <https://zaiste.net/>.
     * `exa` might be my favorite. Install it with the following command.
     * `cargo install exa`
     * `jless` is a CLI tool for helping you view JSON. Install it with the following command.
     * `cargo install --git https://github.com/PaulJuliusMartinez/jless`
37. Install [`gron`](https://github.com/tomnomnom/gron)
   > Make JSON greppable!
     1. `brew install gron`
38. Install and configure linting for Markdown
     1. Install [`markdownlint-cli2`](https://github.com/DavidAnson/markdownlint-cli2):
         * `npm install markdownlint-cli2 --global`
     1. Install [`markdownlint-cli2-formatter-pretty`](https://github.com/DavidAnson/markdownlint-cli2/tree/main/formatter-pretty)
         * `npm install markdownlint-cli2-formatter-pretty --global`
     1. Clone <https://github.com/dgroomes/markdownlint-playground>
     1. Build the `lint-rules/` package
         * `cd lint-rules; npm install -g`
     1. Use the alias `mdlint` to lint a file. See earlier instructions to configure Bash with this and other aliases.
39. Install the AWS CLI
     * Follow the [installation instructions in the AWS doc site](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
       I followed the GUI instructions.
40. Install the AWS Cloud Development Kit (CDK) CLI
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


## Wish List

General clean-ups, TODOs and things I wish to implement for this project

* [x] DONE System for measuring the time it takes to load scripts in `.bashrc` and `.bash_profile`. I want to do something
  like [this very cool project](https://github.com/colindean/hejmo/blob/0f14c6d00c653fcbb49236c4f2c2f64b267ffb3c/dotfiles/bash_profile#L93)!
* [ ] Loading my bash completions is slow. Doesn't bash completions support lazy loading? I have some good notes in `bash/BASH_COMPLETION.md`.
  Maybe most software still only provides v1 completion (which doesn't support lazy/on-demand)...
