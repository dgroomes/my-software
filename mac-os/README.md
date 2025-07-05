# mac-os

My personal instructions for configuring macOS the way I like it and installing the tools I use.


## Instructions

This a long list, but it's just one list, it's detailed, and I tread it often enough (every year or two) that it's
accurate and useful. Not all items need to be expressed in an order, but many of them do and so the "it's just a list"
top-down approach is a good thing. It's not perfect. Some of the order is wrong especially with regard to bootstrapping
to a working Nushell environment, but it's great enough.

1. Configure macOS system settings
    * `System Settings > Keyboard > Keyboard Shortcuts... > Modifier Keys` and configure "Caps Lock key" to perform "Control"
    * `System Settings > Keyboard > Keyboard Shortcuts... > Function Keys` and toggle on "Use F1, F2, etc. keys as standard function keys"
    * `System Settings > Keyboard > Press (globe) key to...` change to `Do nothing` so that it doesn't annoyingly bring
      up the character/emoji picker even when I'm using the function key to do something like change the volume.
    * Remove clutter macOS app icons from the Dock. Remove an icon with the context menu item "Remove from Dock".
    * `System Settings > Desktop & Dock > Automatically hide and show the Dock`
    * `System Settings > Control Center > Clock Options > Display the time with seconds`
    * `System Settings > Control Center > Battery > Show percentage`
    * `System Settings > General > AirDrop & Handoff` and turn `AirPlay Receiver` off because [it uses port 500](https://developer.apple.com/forums/thread/682332).
2. Install Xcode from the app store
    * Agree to the license (try to execute `git` in the terminal and it will prompt you to read the license and agree to it)
    * Run the Command Line Tools (CLT) because this is at least needed for Homebrew and imagine other stuff. Run the following command.
    * `xcode-select --install`
3. Install Raycast <https://www.raycast.com> and configure it.
    * During the getting started flow, enable the window management extension.
    * Enable [Cmd + Space to launch Raycast](https://manual.raycast.com/hotkey) instead of the Spotlight launcher by following the next steps.
    * `System Settings > Keyboard > Keyboard Shortcuts... > Spotlight` and uncheck `Show Spotlight search` and `Show Finder search window`
    * Open Raycast settings, click `Raycast Hotkey`, and press `Cmd + Space` 
    * Configure window management keyboard shortcuts by following the next steps.
    * Open Raycast settings, go to `Extensions`
    * Type "Window Management" and disable the extension. We only want to enable a select few commands. 
    * Type "Left Half", click "Record Hotkey", and press `Ctrl + [`
    * Type "Right Half", click "Record Hotkey", and press `Ctrl + ]`
    * Type "Maximize", click "Record Hotkey", and press `Ctrl + \`
    * Alternatively to Raycast's window management, install Rectangle <https://github.com/rxhanson/Rectangle>
    * Uncheck all keyboard shortcuts. Configure the following:
        * "Left Half": `Ctrl + [`
        * "Right Half": `Ctrl + ]`
        * "Maximize": `Ctrl + \`
4. Clone this repository
    * First make the "repos" directory with `mkdir -p ~/repos/personal`
    * `cd ~/repos/personal && git clone https://github.com/dgroomes/my-software.git`
    * Finally, move to this directory because many of the later setup steps assume you are in this directory because they use relatives paths: `cd my-software`
5. Install Ghostty <https://ghostty.org>. Configure it with my configuration:
    * ```shell
      mkdir -p ~/.config/ghostty/themes/

      cp ghostty/config ~/.config/ghostty/
      cp ghostty/my-theme ~/.config/ghostty/themes/
      ```
6. Install Homebrew <https://brew.sh/>
    * Download and install it using the `.pkg` installer.
    * Install the shell completion into the right place. `bash-completion` has so much auto-discovery, and Homebrew is
      so all-in on Bash that you think you wouldn't need to do this, but you do. Use the following command.
    * ```shell
      mkdir -p ~/.local/share/bash-completion/completions && ln -s /opt/homebrew/completions/bash/brew ~/.local/share/bash-completion/completions/brew
      ```
7. Install my own formulas
    * This is an experiment. I'm trying out maintaining my own Homebrew formulas.
    * ```shell
      brew tap dgroomes/my-software "$PWD"
      brew install dgroomes/my-software/my-open-jdk@11
      brew install dgroomes/my-software/my-open-jdk@17
      brew install dgroomes/my-software/my-open-jdk@21
      brew install dgroomes/my-software/my-node@20
      brew install dgroomes/my-software/my-node@23
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
   * Copy over the `.bash_profile` to the home directory with the following command.
   * ```shell
     cp bash/.bash_profile ~
     ```
   * Open a new Bash session and enjoy the custom environment variables, etc.
10. Install 'bash-completion'.
     * ```shell
       brew install bash-completion@2
       ```
     * See additional information in `bash/README.md`.
11. Install Nushell, configure it and make it the default shell
     * WARNING: There is a bootstrapping problem. You need to skip ahead and install Rust and Rust-based tools. I don't
       want to re-arrange that right now because the change is getting unwieldy due to other updates. 
     * ```nushell
       cd nushell
       ```
     * ```nushell
       $env.DO_DIR = (pwd)
       ```
     * ```nushell
       overlay use --prefix do.nu
       ```
     * Clone the nu_scripts repository.
     * ```nushell
       mkdir ~/repos/opensource
       git clone https://github.com/nushell/nu_scripts.git ~/repos/opensource/nu_scripts
       ```
     * Go through and do all the `do install ...` commands.
     * Start a fresh Nushell session and enjoy the customized environment.
     * Addendum (consider consolidating this into the install flow): install the bundled Nushell plugins with the
       following commands.
     * ```nushell
       plugin add nu_plugin_gstat
       ```
12. Install [Atuin](https://github.com/atuinsh/atuin)
     * Install Atuin and copy over my config with the following commands.
     * ```shell
       brew install atuin
       ```
     * ```shell
       cp atuin/config.toml ~/.config/atuin/config.toml
       ```
13. Install JetBrains Toolbox <https://www.jetbrains.com/toolbox-app/>
    * Open Toolbox
    * Log in to your JetBrains account
    * Install Intellij Ultimate
    * In `my-software`, build my JetBrains preferences file (`settings.zip`). See instructions in `jetbrains/README.md`
    * Open this project in Intellij from the command line with the following command.
    * ```shell
      idea .
      ```
    * Import settings from the `settings.zip` created earlier
    * Disable unneeded plugins (there are a lot!)
    * Install desired plugins (which ones do I like? JetBrains is pretty great about bundling and supporting tons already
      that I don't need many third-party ones).
    * In macOS settings, disable the "Cmd + Shift + A" system keyboard shortcut so it does not conflict with the
      "Find Action" Intellij keyboard shortcut. See instructions at <https://intellij-support.jetbrains.com/hc/en-us/articles/360005137400-Cmd-Shift-A-hotkey-opens-Terminal-with-apropos-search-instead-of-the-Find-Action-dialog>
14. Install `jq`
     * ```shell
       brew install jq
       ```
15. Install `kcat`
     * ```shell
       brew install kcat
       ```
16. Install Python core components
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
     * Install `pipx` shell completion and [argcomplete](https://github.com/kislyuk/argcomplete) because it's a dependency.
     * ```nushell
       pipx install argcomplete
       ```
     * ```nushell
       mkdir ~/.local/share/bash-completion/completions/ ; register-python-argcomplete pipx | save ~/.local/share/bash-completion/completions/pipx
       ```
     * Install [Poetry](https://python-poetry.org)
     * ```nushell
       pipx install poetry
       ```
17. Install Starship <https://github.com/starship/starship>
     * > The minimal, blazing-fast, and infinitely customizable prompt for any shell!
     * ```shell
       brew install starship
       ```
     * For more information, read the official instructions in the [Starship README.md](https://github.com/starship/starship#-installation).
     * Copy over the custom Starship config file with the following command.
     * ```shell
       mkdir -p ~/.config && cp starship/starship.toml ~/.config
       ```
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
           git config --global alias.lg "log --pretty=format:'%C(black dim)%ad%C(auto)%d%n%s%n' --date=relative"
           ```
             * Create a cool alternative to `git log` named `git lg`
         * ```shell
           git config --global alias.st "status --short --branch"
           ```
             * Create a status alias with more compact output
         * ```shell
           git config --global alias.br  "branch --sort=-committerdate --format='%(committerdate:relative)	%(refname:short)'"
           ```
             * Create a branch alias that orders by latest commit date. The date is formatted like "35 hours ago", "6 days ago", etc.
               I almost always want to see latest first. The relative date helps me understand if it was something I can jump
               back into easily because it's recent or something so old I would need to make an effort.
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
         * ```nushell
           ".DS_Store" | save ~/.gitignore_global
           git config --global core.excludesfile ~/.gitignore_global
           ``` 
         * The exclusions described by a global gitignore file should be sparing for two reasons. 1) If a project is
           shared, it's convenient for everyone else if the exclusions are version-controlled in the project-specific
           gitignore file. 2) Projects are diverse and unpredictable. There might be a project that wants to version-control
           the `build/` or `out/` directories, and for good reason. For me, the `.DS_Store` exclusion is a very safe bet. 
20. Install Docker Desktop <https://docs.docker.com/desktop/install/mac-install/>
     * Disable phone-home telemetry
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
        ```nushell
        mkdir ~/.config/karabiner/assets/complex_modifications
        cp karabiner/karabiner.json ~/.config/karabiner
        cp karabiner/assets/complex_modifications/* ~/.config/karabiner/assets/complex_modifications
        ```
22. Install Go <https://golang.org/dl/>
     * Note: Consider installing manually or using something like Homebrew. There are pros and cons to each approach.
       To install using Homebrew, use the following command.
     * ```shell
       brew install go
       ```
23. Install Postgres
     * ```nushell
       brew install postgresql@17
       ```
24. Install `gh` https://github.com/cli/cli
     1. ```shell
        brew install gh
        ```
     2. Use it for the first time and log in.
25. Install Rust
     1. Install `rustup` using the instructions in the official [rust-lang site](https://www.rust-lang.org/tools/install)
     and **do not** allow it to modify the `PATH`.
26. Rust-based tools
     * There is a nascent but rich ecosystem of Rust-based command-line tools. Many of them are substitutes for traditional
       commands like `ls`, `du`, and `cat` but they bring a bevy of extra features. Best of all, they are fast. Keep track
       of this "re-implemented in Rust" trend and follow this great article [*Rewritten in Rust: Modern Alternatives of Command-Line Tools*](https://zaiste.net/posts/shell-commands-rust/)
       on <https://zaiste.net/>.
     * [`zoxide`](https://github.com/ajeetdsouza/zoxide) is "a smarter `cd` command". Install it with the following command.
     * ```nushell
       cargo install zoxide --locked
       ```
27. Install [CleanShot](https://cleanshot.com/)
    * Enter the license key
    * Go through the configuration steps in the prompt.
28. Install Sublime text
    * Set `"color_scheme": "auto"` in the settings JSON file.
29. Configure Safari settings
    * Follow this [StackExchange answer](https://apple.stackexchange.com/a/214748) to change the behavior of `Cmd + W`
      so that it doesn't close the whole window when only pinned tabs are left.
    * `System Settings > Keyboard > Keyboard Shortcuts... > App Shortcuts`
    * Add a shortcut for "Safari", for menu item "Close Tab", shortcut `Cmd + W`.
30. Install Go-based tools in `go/`
31. Install Java-based tools in `java/`
32. Install Python-based tools in `python/`
33. Clone all my repos
    * Clone my `dgroomes/dgroomes` repository and use the Python script to get a JSON representation of all my repos.
      Then, use a command like the following to clone all of them.
    * ```nushell
      do {
        cd ~/repos/personal
        open ~/repos/personal/dgroomes/repos.json | where ($it.archived == false and not ($it.name | path exists)) | each { |repo| git clone $repo.clone_url }
      }
      ```
34. Install [dust](https://github.com/bootandy/dust)
    * ```nushell
      brew install dust
      ```
35. Configure Gradle's ["custom toolchain locations"](https://docs.gradle.org/current/userguide/toolchains.html#sec:custom_loc)
    * Create the `~/.gradle/gradle.properties` file and add the following line
    * ```text
      org.gradle.java.installations.fromEnv=JAVA_11_HOME,JAVA_17_HOME,JAVA_21_HOME
      ```
36. Setup Bash completion for Git
    * There is a special case for supporting Bash completion of the `git` command. Annoyingly, git is the only
      Homebrew-installed package that I use which distributes its Bash completion script in an incompatible naming
      scheme. It uses the name `git-completion.bash`. It needs to be either `git` (my preference and the norm) or
      `git.bash` (perfectly fine too). An inexpensive fix for this is to symlink the `git-completion.bash` file to `git`
      in the conventional "local" Bash completions directory. The 'bash-completion' library will find it
      there.
    * ```nushell
      mkdir ~/.local/share/bash-completion/completions
      ln -sf /opt/homebrew/etc/bash_completion.d/git-completion.bash ~/.local/share/bash-completion/completions/git 
      ```
37. Install uv
    * TODO
38. Install [`mc`, the Minio CLI](https://github.com/minio/mc)
    * ```nushell
      brew install minio/stable/mc
      ```
    * `mc`'s shell completion is implemented by <https://github.com/posener/complete> which I think is a fantastic way
      for shell completion to be implemented. I think there really ought to be a standard interface for CLIs to be
      interrogated for their completion options. But, oddly, `mc`'s Homebrew installation doesn't distribute with the
      completions file. This is fine, and there is virtually nothing to it anyway, just a `complete -C ...` command.
      Let's write it ourselves.
    * ```nushell
      "complete -C /opt/homebrew/bin/mc mc" | save ~/.local/share/bash-completion/completions/mc
      ```
39. Hide noisy login message when starting a shell session:
    * ```shell
      touch ~/.hushlogin
      ```
40. Set up `.npmrc` file
    * ```nushell
      mkdir ~/.local/npm/lib
      npm config set prefix ~/.local/npm
      ```
41. Activate the `do.nu` script
    * ```nushell
      overlay use --prefix do.nu
      ```
    * Note: I'm finally to the point of scripting out the setup. Ideally this step should come earlier in the process,
      but bootstrapping matters. Over time, push this earlier and incorporate more of the steps into the `do.nu` script
42. Install LLM agent rules
    * ```nushell
      do llm-rules
      ```
43. Install LLM prompts
    * ```nushell
      do llm-prompts
      ```
