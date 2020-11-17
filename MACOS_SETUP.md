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
1. macOS preferences
    * `Clock preferences > Show Date`
    * `Battery > Show percentage`
    * `Preferences > Dock > Automatically hide and show the Dock`
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
    * Install Intellij
    * Disable unneeded plugins
    * Enable shell integration. Go to the Toolbox App Settings in the top right corner (click the hexagon), expand "Shell Scripts", enable the toggle, and set the location to `/usr/local/bin`
    * Build my JetBrains preferences file (`settings.zip`). See instructions in the root `README.md`
    * Open Intellij from the command line with `idea .` 
    * Log in to your JetBrains account (for some reason this didn't work for me in ToolBox. Nothing happened when I
      clicked "Log in". So, I just logged in in Intellij)
    * Enable "Use non-modal commit interface". See <https://www.jetbrains.com/help/idea/managing-changelists.html>
      Can I save this in my Intellij preferences
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
1. Install the "powerline" status line <https://powerline.readthedocs.io/en/master/installation/osx.html>
    * `pip3 install --user powerline-status`
    * Add initialization commands to your `.bashrc`. Follow <https://powerline.readthedocs.io/en/master/usage/shell-prompts.html#bash-prompt>
      Specifically, add:
        ```
        # Configure and initialize the powerline-status line https://powerline.readthedocs.io/en/master/usage/shell-prompts.html#bash-prompt
        powerline-daemon -q
        POWERLINE_BASH_CONTINUATION=1
        POWERLINE_BASH_SELECT=1
        . /Users/davidgroomes/Library/Python/3.9/lib/python/site-packages/powerline/bindings/bash/powerline.sh
        ```
    * Do the fonts installation `git clone https://github.com/powerline/fonts.git ~/repos/opensource/fonts && cd ~/repos/opensource/fonts && ./install.sh && cd -`
    * Restart iTerm2, configure "Use a different font for non-ASCII text" and choose the DejaVu font to get the Powerline arrow symbols
    * Install a powerline git status extension <https://github.com/jaspernbrouwer/powerline-gitstatus> 
      * `pip3 install --user powerline-gitstatus`
    * Copy the configuration files into the powerline config directory
      * `cp -r powerline ~/.config/powerline`      
      * You will have to restart the powerline daemon for the config change to take effect: `powerline-daemon --replace`
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
      * `git config --global user.email johndoe@example.com`
      * `git config --global pull.ff only`
      * `git config --global init.defaultBranch main`
    * Configure `git` credentials to Github. Follow <https://help.github.com/en/github/authenticating-to-github/accessing-github-using-two-factor-authentication#using-two-factor-authentication-with-the-command-line>
    * Use credentials helper <https://help.github.com/en/github/using-git/caching-your-github-password-in-git>
      * `git config --global credential.helper osxkeychain`
      * The next time you `git push` you will get a popup. Enter your password and choose "Always allow"
1. Install Docker <https://hub.docker.com/editions/community/docker-ce-desktop-mac/>
    * Install Bash completion for `docker`: `curl https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker -o /usr/local/etc/bash_completion.d/bash`
    * Install Bash completion for `docker-compose`: `curl https://raw.githubusercontent.com/docker/compose/1.25.4/contrib/completion/bash/docker-compose -o /usr/local/etc/bash_completion.d/docker-compose`
1. Install Karabiner-Elements from source <https://github.com/pqrs-org/Karabiner-Elements> and configure it with.
    1. First, we must configure Xcode command line tools correctly. Follow these instructions <https://stackoverflow.com/a/61725799>
    1. Then, install `xcodegen` from source <https://github.com/yonaskolb/XcodeGen>:
     ```
     git clone --depth 1 https://github.com/yonaskolb/XcodeGen.git
     cd XcodeGen
     make install
     ```
    1. 
     ```
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
1. Install Golang <https://golang.org/dl/>
    * Create the go home dir `mkdir -p ~/go`
    * Make a best attempt at configuring the Go environment variables (reference <https://stackoverflow.com/questions/7970390/what-should-be-the-values-of-gopath-and-goroot>) 
        * Add to `~/.bashrc`: `export GOPATH="$HOME/go"`
        * Add to `~/.bashrc`: `export PATH="$PATH:$GOPATH/bin"`
    * Download and install Bash completion for `go` from <https://github.com/posener/complete/tree/master>. Warning, the
      branching is a little confusing. I'm not sure what the latest stable version of the software is.
        * `go get -u github.com/posener/complete/gocomplete` (I couldn't get `go get -u github.com/posener/complete/v2/gocomplete` to work)
        * `gocomplete -install` (how does this work?)
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
    
### Optional

1. `git clone --depth 1 https://github.com/vsch/idea-multimarkdown`
