# my-config 

Personal configuration stuff including dot files, installation instructions and other configuration files.


## Overview

The most useful component of this repository is the [My macOS Setup](#my-macos-setup) section below. It provides
step-by-step instructions I like to follow for setting up a new Mac.

The rest of the repository is organized in the following directories:


### `bash/`

My Bash config and notes about Bash auto-completion (I always forget how to set this up!).


### `homebrew/`

A description of my Homebrew strategy.


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


### `nushell`

My Nushell configuration.


### `starship/`

My config file for Starship.

> The minimal, blazing-fast, and infinitely customizable prompt for any shell!
>
> -- <cite>https://github.com/starship/starship</cite>


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
2. Install Xcode from the app store
    * Agree to the license (try to execute `git` in the terminal and it will prompt you to read the license and agree to it)
3. Install Rectangle <https://github.com/rxhanson/Rectangle> for fast and easy window resizing
    * Uncheck all keyboard shortcuts. Configure the following:
        * "Left Half": `Ctrl + [`
        * "Right Half": `Ctrl + ]`
        * "Maximize": `Ctrl + \`
4. Clone this repository
    * First make the "repos" directory with `mkdir -p ~/repos/personal`
    * `cd ~/repos/personal && git clone https://github.com/dgroomes/my-config.git`
    * Finally, move to this directory because many of the later setup steps assume you are in this directory because they use relatives paths: `cd my-config`
5. Install iTerm2 <https://iterm2.com/downloads.html>. Configure it with my configuration:
    * Create the iTerm config directory with  `mkdir -p ~/.config/iterm2`
    * Copy the plist file with `cp iterm2/com.googlecode.iterm2.plist ~/.config/iterm2/com.googlecode.iterm2.plist`
    * Open iTerm and navigate to `Preferences > General > Preferences`. Check `Load preferences from a custom folder or URL` and set it
      to `~/.config/iterm2`.
    * A prompt will come up to save the current settings. Do *not* save the current settings.
    * Check `Save changes to folder when iTerm2 quits`.
    * Restart iTerm
6. Install Homebrew <https://brew.sh/>
    * Make sure to install Homebrew in the Apple Silicon configuration. I won't repeat the details here, but basically,
      it should be installed at `/opt/homebrew` and not `/usr/local`.
7. Install my own formulas
    * This is an experiment. I'm trying out maintaining my own Homebrew formulas.
    * ```shell
      brew tap dgroomes/my-config "$PWD"
      ```
    * ```shell
      brew install dgroomes/my-config/my-open-jdk@17
      ```
   *  ```shell
      brew install dgroomes/my-config/my-open-jdk@21
      ```
8. Install Bash
    * macOS uses a years old version of Bash and will never update it because of licensing. We'll use Homebrew to install a modern version of Bash.
      First, initialize the Homebrew environment config with the following command (yes, this is awkward but the nature of bootstrapping systems is
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
     * Run the `bash/sync-homebrew-managed-bash-completions.pl` script whenever you install a Homebrew package that comes with completion
       scripts. For more information, read the notes in that script.
11. Install [Atuin](https://github.com/atuinsh/atuin)
     * Install Atuin with the following command.
     * ```shell
       brew install atuin
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
15. Install Python core components
     * There are multiple ways to install Python. Using the official installer is a perfectly valid approach. I'm already
       invested in Homebrew, and it's a good choice for me. Use the following command.
     * ```shell
       brew install python
       ```
     * The Python installation managed by Homebrew is considered an ["externally managed" installation, and the Python
       docs](https://packaging.python.org/en/latest/specifications/externally-managed-environments/) describe what this
       means in detail. Consider reading those docs carefully because it will help you navigate the many facets of
       managing the Python ecosystem on your computer. An effect of all this is that we should also install `pipx`
       directly from Homebrew (and basically never use the `pip3` binary that comes with the Python installation). We'll
       use `pipx` to install Python packages globally for the user, like `poetry`, and others. Use the following command.
     * ```shell
       brew install pipx
       ```
16. Install Starship <https://github.com/starship/starship>
     * > The minimal, blazing-fast, and infinitely customizable prompt for any shell!
     * ```shell
       brew install starship
       ```
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
19. Install latest `git` and configure it
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
             * Use Sublime Text as the editor instead of Vim. This is for things like git rebase and amend operations.
               See [this nice GitHub doc](https://docs.github.com/en/get-started/getting-started-with-git/associating-text-editors-with-git)
               about configuring external editors.
         * ```shell
           git config --global push.autoSetupRemote true
           ```
             * This makes it so that your first `git push` will work, and you don't need `git push --set-upstream ...`.
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
           and doesn't give an error message.
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
20. Install Docker Desktop <https://docs.docker.com/desktop/install/mac-install/>
     * Then, install Bash completion for `docker` and `docker-compose` by following [the docs](https://docs.docker.com/desktop/faqs/macfaqs/#how-do-i-install-shell-completion). It boils down to:
       ```bash
       ln -s /Applications/Docker.app/Contents/Resources/etc/docker.bash-completion ~/.local/share/bash-completion/completions/docker
       ln -s /Applications/Docker.app/Contents/Resources/etc/docker-compose.bash-completion ~/.local/share/bash-completion/completions/docker-compose
       ```
     * Configure Docker to use fewer resources. Consider only 2-3 cores and 6GB (but it depends on the need and constraints).
21. Install Karabiner-Elements <https://github.com/pqrs-org/Karabiner-Elements> from source (or Homebrew) and configure it with.
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
22. Install Insomnia <https://insomnia.rest/download/>
23. Install Go <https://golang.org/dl/>
     * Note: Consider installing manually or using something like Homebrew. There are pros and cons to each approach.
       To install using Homebrew, use the following command.
     * ```shell
       brew install go
       ```
24. Install Bash completion for Gradle
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
25. Install `libpq` so we can get `psql`
     * Follow directions at <https://blog.timescale.com/tutorials/how-to-install-psql-on-mac-ubuntu-debian-windows/>
     * `brew install libpq`
     * `brew link --force libpq`
26. Build and install Apache JMeter, a load testing and performance measurement tool
     1. `git clone https://github.com/apache/jmeter`
     2. Build it with `./gradlew createDist`
     3. Add the `bin/` directory to the path.
         * For example, append something like `export PATH="$PATH:~/repos/opensource/jmeter/bin"` to your `.bashrc`
27. Install `gh` https://github.com/cli/cli
     1. ```shell
        brew install gh
        ```
     2. Use it for the first time and log in.
     3. Generate a 'bash-completion' completion file and save it to a file. Use the following command.
     4. ```shell
        gh completion --shell bash > "$HOME/.local/share/bash-completion/completions/gh"
        ``` 
28. Install MongoDB *Community Server*
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
29. Install Rust
     1. Install `rustup` using the instructions in the official [rust-lang site](https://www.rust-lang.org/tools/install)
     and **do not** allow it to modify the `PATH`.
     2. Install `rustup` and `cargo` Bash completions with the following commands.
     3. ```shell
        rustup completions bash > "$HOME/.local/share/bash-completion/completions/rustup"
        rustup completions bash cargo >> "$HOME/.local/share/bash-completion/completions/cargo"
        ```
30. Rust-based tools
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
31. Install the AWS CLI
     * Follow the [installation instructions in the AWS doc site](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
       I followed the GUI instructions.
32. Install [CleanShot](https://cleanshot.com/)
    * Enter the license key
    * Go through the configuration steps in the prompt.
33. Install Rosetta
    * ```shell
      softwareupdate --install-rosetta
      ```
    * I don't love that I have to do this (to support some rare binaries like Java gRPC codegen) because sometimes I might
      forget that I'm running a binary that is not native to the M1 chip. But, I'm doing it anyway.


## Wish List

General clean-ups, TODOs and things I wish to implement for this project

* [ ] Consider restoring (at `b3154dde` and before) the shortcuts I had defined for `navi`. There was some good knowledge there, but I never wound
  up using `navi`.
* [ ] Consider restoring (at `b3154dde` and before) my usage of markdownlint. I still like it, but I just never got used to using it.
  learn them better. I think I should pare down the larger one-liners.
* [ ] Properly add Nushell steps to instructions. Bootstrapping is important.
* [ ] Consider restoring (at `b3154dde` and before) my Postgres-related Bash functions. These were hard fought and useful. Maybe reimplement in
  Nushell. Alternatively, I often use Postgres in Docker. But still. (Same is true of the Mongo functions but not sure
  how much I'll ever use Mongo again.)
* [ ] (SKIP: virtual environments satisfy Python version switching) Python SDK management. Don't bother with custom formula. Just use the core ones, which already include
  3.9, 3.10, 3.11 and 3.12. That's perfect. UPDATE: I think Python switching is not as necessary as Java or Node.js
  switching because we often use virtual environments. So, in a Python project, you typically activate its virtual env
  and that's your way of switching Python versions. And for one-off scripts, would I just be using the latest Python
  anyway? I'm going to skip this for now.
* [x] DONE Node.js SDK management (I think this should be totally feasible since I figured this out with OpenJDK and am happy
  with that).
* [ ] Why isn't `enter_accept = true` working for Atuin? It has no effect.


## Finished Wish List Items

* [x] DONE System for measuring the time it takes to load scripts in `.bashrc` and `.bash_profile`. I want to do something
  like [this very cool project](https://github.com/colindean/hejmo/blob/0f14c6d00c653fcbb49236c4f2c2f64b267ffb3c/dotfiles/bash_profile#L93)!
* [x] DONE (The answer is: never use eager completion loading) Loading my bash completions is slow. Doesn't bash completions support lazy loading? I have some good notes in `bash/BASH_COMPLETION.md`.
  Maybe most software still only provides v1 completion (which doesn't support lazy/on-demand)...
* [x] DONE Create my personal framework/strategy for managing "scripts to source during Bash shell initialization time"
    * DONE Scaffold out a Perl script
* [ ] SKIP Add more external documentation to `bb` (the internal documentation in the '--help' is already extremely thorough)
* [ ] SKIP (bb is complete) Implement the fifo/domain-socket -based benchmarking described in `bb`
