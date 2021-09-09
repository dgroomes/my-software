# My macOS setup

1. Set up the keyboard (if using a Windows keyboard)
    * Open `System Preference > Keyboard >  Modifier Keys`
    * Select the keyboard from the `Select keyboard` dropdown
    * Map the following:
      * "Caps lock" to "Control"
      * "Command" to "Option" (if on an external Windows keyboard)
      * "Option" to "Command" (if on an external Windows keyboard)
    * "Use F keys as F keys"
1. Install Xcode from the app store
    * Agree to the license (try to execute `git` in the terminal and it will prompt you to read the license and agree to it)
1. Install Rectangle <https://github.com/rxhanson/Rectangle> for fast and easy window resizing
    * Uncheck all keyboard shortcuts. Configure the following:
        * "Left Half": `Ctrl + [`
        * "Right Half": `Ctrl + ]`
        * "Maximize": `Ctrl + \`
1. macOS System Preferences
    * `Dock & Menu Bar > Automatically hide and show the Dock`
    * `Dock & Menu Bar > Clock > Show date` and `Show the day of the week`
    * `Dock & Menu Bar > Battery > Show percentage`
1. Clone this repository
    * First make the "repos" directory with `mkdir -p ~/repos/personal`
    * `cd ~/repos/personal && git clone https://github.com/dgroomes/my-config.git`
    * Finally, move to this directory because many of the later setup steps assume you are in this directory because they use relatives paths: `cd my-config`
1. Install iTerm2 <https://iterm2.com/downloads.html>. Configure it with my configuration:
    * Create the iTerm config directory with  `mkdir -p ~/.config/iterm2`
    * Copy the plist file with `cp iterm2/com.googlecode.iterm2.plist ~/.config/iterm2/com.googlecode.iterm2.plist`
    * Open iTerm and navigate to `Preferences > General > Preferences`. Check `Load preferences from a custom folder or URL` and set it 
      to `~/.config/iterm2`.
    * A prompt will come up to save the current settings. Do *not* save the current settings.
    * Check `Save changes to folder when iTerm2 quits`.
    * Restart iTerm
1. Install JetBrains Toolbox <https://www.jetbrains.com/toolbox-app/>
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
1. Install Homebrew <https://brew.sh/>
1. `brew install bash`
    * macOS uses a years old version of Bash and will never update it because of licensing
    * After installing from Homebrew, you will need to change the default shell with the following.:
    * `sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'`
    * `chsh -s /usr/local/bin/bash`
    * Open a new session and verify the new version of Bash is being used `echo $BASH_VERSION`
    * Copy over the `.bash_profile` to the home directory with: `cp bash/.bash_profile ~`
    * Create a `.bashrc` with `touch ~/.bashrc`
    * Add colors to Bash. Add the following to `~/.bashrc`: `export CLICOLOR=1`
1. Install bash completion. See additional information in `bash/BASH_COMPLETION.md`
    * Execute `brew install bash-completion@2`
    * Add `BASH_COMPLETION_COMPAT_DIR="/usr/local/etc/bash_completion.d"` to `~/.bashrc`
    * Add `[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"` to `~/.bashrc`
    * For reference, see: <https://github.com/Homebrew/homebrew-core/blob/fecd9b0cb2aa855ec24c109ff2b4507c0b37fb2a/Formula/bash-completion%402.rb#L36>
1. Copy `bash/bash-aliases.sh` and `bash/bash-functions.sh` to `~/.config/bash/` and source them from your `.bashrc`
    * Create the directory with `mkdir ~/.config/bash`
    * `cp bash/bash-*.sh ~/.config/bash`
    * Add the following to your `.bashrc`:
      ```
      # Source configuration files
      for filename in ~/.config/bash/*.sh; do
          if [[ ! -e "$filename" ]]; then              
            echo >&2 "Bash configuration files not found!"
            continue
          fi
          . "$filename"
      done
      ``` 
1. `brew install jq`
1. `brew install kafkacat`
1. Install Python 3 <https://www.python.org/downloads/> 
    * `sudo pip3 install --upgrade pip`
    * Add user-installed Python packages to the `PATH` by adding this line in `.bashrc`: `export PATH="$PATH:/Users/davidgroomes/Library/Python/3.9/bin"`
1. Install Starship <https://github.com/starship/starship>
    * > The minimal, blazing-fast, and infinitely customizable prompt for any shell!
    * `brew install starship`
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
1. Add `~/.inputrc`
    * `cp .inputrc ~`
1. Install bash completion for `pip`: `pip3 completion --bash > /usr/local/etc/bash_completion.d/pip`
1. Install SDKMAN <https://sdkman.io/>
    * Install a community-provided Bash completion script for SDKMAN with `curl https://raw.githubusercontent.com/Bash-it/bash-it/ac5a8aca47f42c6feab6bde3fb7e5a06d53f28ff/completion/available/sdkman.completion.bash -o /usr/local/etc/bash_completion.d/sdkman` 
    * Install the latest LTS (Java 11) and the latest Java (Java 15)
    * Install the latest version of Gradle
    * Install the latest version of Maven
    * Install `visualvm` and then configure visualvm to use the Java 8.
       * Follow the instructions at <https://gist.github.com/gavvvr/c9891684f9ef062502d58c80903be5cc>
       * Specifically, edit the file `~/.sdkman/candidates/visualvm/current/etc/visualvm.conf` 
1. Install `nvm` Node Version Manager <https://github.com/nvm-sh/nvm> and Node.js
    * Install the latest Long-Term Support version of node with `nvm install --lts`
    * Install npm completion with `npm completion > /usr/local/etc/bash_completion.d/npm`
    * Install a community-provided Bash completion script for npx with `curl https://gist.githubusercontent.com/gibatronic/44073260ffdcbd122e9520756c8e35a1/raw/54cacab82b57ce965cf9f69edcd3477d81e1fa58/complete_npx -o /usr/local/etc/bash_completion.d/npx`
1. Enable "Tab Hover Cards" in Chrome
    * Open `chrome://flags/` in Chrome
    * Set "Tab Hover Cards" to enabled
    * Set "Tab Hover Card Images" to enabled
    * Tab Hover Cards make it faster to preview the title of a tab 
1. Install latest `git` and configure it
    * `brew install git`
    * Configure `git` config <https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup>
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
    * Configure `git` credentials to Github. Follow <https://help.github.com/en/github/authenticating-to-github/accessing-github-using-two-factor-authentication#using-two-factor-authentication-with-the-command-line>
    * Use credentials helper <https://help.github.com/en/github/using-git/caching-your-github-password-in-git>
       * `git config --global credential.helper osxkeychain`
       * The next time you `git push` you will get a popup. Enter your password and choose "Always allow"
1. Install Docker <https://hub.docker.com/editions/community/docker-ce-desktop-mac/>
    * Then, install Bash completion for `docker` and `docker-compose` by following [the docs](https://docs.docker.com/docker-for-mac/#bash). It boils down to:
      ```
      ln -s /Applications/Docker.app/Contents/Resources/etc/docker.bash-completion /usr/local/etc/bash_completion.d/docker
      ln -s /Applications/Docker.app/Contents/Resources/etc/docker-compose.bash-completion /usr/local/etc/bash_completion.d/docker-compose
      ```
1. Install Karabiner-Elements from source <https://github.com/pqrs-org/Karabiner-Elements> and configure it with.
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
1. Install Insomnia <https://insomnia.rest/download/>
1. Install Go <https://golang.org/dl/>
    * Create the go home dir `mkdir -p ~/repos/go`
    * Make a best attempt at configuring the Go environment variables (
      reference <https://stackoverflow.com/questions/7970390/what-should-be-the-values-of-gopath-and-goroot>)
        * Add to `~/.bashrc`: `export GOPATH="$HOME/repos/go"`
        * Add to `~/.bashrc`: `export PATH="$PATH:$GOPATH/bin"`
    * Download and install Bash completion for `go` from <https://github.com/posener/complete/tree/master> (You might
      notice that the default branch is "v1" but this is only for legacy reasons. Read the project's README for more
      info.)
1. Install Bash completion for Gradle
    * `curl https://raw.githubusercontent.com/gradle/gradle-completion/7b084bd68c79be27b8200c7a25e6d00c9c65f9a9/gradle-completion.bash -o /usr/local/etc/bash_completion.d/gradle-completion.bash`
1. Install `libpq` so we can get `psql`
    * Follow directions at <https://blog.timescale.com/tutorials/how-to-install-psql-on-mac-ubuntu-debian-windows/>
    * `brew install libpq`
    * `brew link --force libpq`
1. Build and install Apache JMeter, a load testing and performance measurement tool
    1. `git clone https://github.com/apache/jmeter`
    1. Build it with `./gradlew createDist`
    1. Add the `bin/` directory to the path.
        * For example, append something like `export PATH="$PATH:~/repos/opensource/jmeter/bin"` to your `.bashrc`
1. Install fzf <https://github.com/junegunn/fzf>
    1. Install it using the git option: <https://github.com/junegunn/fzf/tree/0db65c22d369026a0a9af079bfa7e8110e850ec9#using-git>
        1. Specifically, execute `git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf` and `~/.fzf/install`
        1. When it prompts for *Do you want to enable fuzzy auto-completion?* Answer yes
        1. When it prompts for *Do you want to enable key bindings?* Answer yes
        1. When it prompts for *Do you want to update your shell configuration files?* Answer yes
1. Install `gh` https://github.com/cli/cli
    1. `brew install gh`
    1. Use it for the first time and log in.
1. Clone `gradle-wrapper-upgrader`
    1. `git clone https://github.com/dgroomes/gradle-wrapper-upgrader.git`
    1. Add it to the PATH
1. Install [navi](https://github.com/denisidoro/navi)
    1. `brew install navi`
    1. Copy of the config files.
       ```
       mkdir -p ~/Library/Application\ Support/navi/cheats/mycheats
       cp navi/*.cheat ~/Library/Application\ Support/navi/cheats/mycheats
       ```   
    
### Optional

1. `git clone --depth 1 https://github.com/vsch/idea-multimarkdown`
1. Install MongoDB *Community Server*
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
1. Install Rust
    1. Install `rustup` using the instructions in the official [rust-lang site](https://www.rust-lang.org/tools/install). 
    1. Add to `~/.config/bash/bash-env.sh`: `source ~/.cargo/env"`
        * This is a slightly clever way to configure the `PATH`. It comes installed with Rust so let's use it (idiomatic).
    1. Install `rustup` Bash autocompletion:
        * `rustup completions bash > "$BASH_COMPLETION_COMPAT_DIR/rustup"`
    1. Install `cargo` Bash autocompletion:
        * Note: the official Rust installation uses different mechanisms for Bash completion between `rustup`, `cargo`, etc.
         Keep an eye out for if/when this improves some day (fingers crossed!).
        * Add to `~/.config/bash/bash-env.sh`: `source "$(rustc --print sysroot)/etc/bash_completion.d/cargo"`
1. Rust-based tools
    * There is a nascent but rich eco-system of Rust-based command-line tools. Many of them are substitutes for traditional
      commands like `ls`, `du`, and `cat` but they bring a bevy of extra features. Best of all, they are fast. Keep track
      of this "re-implemented in Rust" trend and follow this great article [*Rewritten in Rust: Modern Alternatives of Command-Line Tools*](https://zaiste.net/posts/shell-commands-rust/)
      on <https://zaiste.net/>.
1. Install [`gron`](https://github.com/tomnomnom/gron)
   > Make JSON greppable!
    1. `brew install gron`
1. Install and configure linting for Markdown
   1. Install [`markdownlint-cli`](https://github.com/igorshubovych/markdownlint-cli):
      * `npm install markdownlint-cli --global`
   1. Clone <https://github.com/dgroomes/markdownlint-playground>
   1. Use the alias `mdlint` to lint a file. See earlier instructions to configure Bash with this and other aliases.
