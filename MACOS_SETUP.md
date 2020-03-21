# My macOS setup

1. Install iTerm2 <https://iterm2.com/downloads.html>. Configure it with my configuration:
    * Create `~/.config/iterm2`
    * Copy `iterm2/com.googlecode.iterm2.plist` to `~/.config/iterm2/com.googlecode.iterm2.plist`
    * Navigate to `Preferences > General > Preferences`. Check `Load preferences from a custom folder or URL` and set it 
      to `~/.config/iterm2`. Check `Save changes to folder when iTerm2 quits`. 
1. Install Homebrew <https://brew.sh/>
1. `brew install bash`
    * macOS uses a years old version of Bash and will never update it because of licensing
    * After installing from Homebrew, you will need to change the default shell with the following.:
    * `sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'`
    * `chsh -s /usr/local/bin/bash`
    * Open a new session and verify the new version of Bash is being used `echo $BASH_VERSION`
    * Add colors to Bash. Add the following to `~/.bashrc`: `export CLICOLOR=1`
1. Install bash completion. See additional information in `bash/BASH_COMPLETION.md`
    * Execute `brew install bash-completion@2`
    * Add `BASH_COMPLETION_COMPAT_DIR="/usr/local/etc/bash_completion.d"` to `~/.bashrc`
    * Add `[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"` to `~/.bashrc`
    * <https://github.com/Homebrew/homebrew-core/blob/fecd9b0cb2aa855ec24c109ff2b4507c0b37fb2a/Formula/bash-completion%402.rb#L36>
1. Copy over the contents of `bash/bash-aliases.sh` and `bash/bash-functions.sh` to your `.bashrc`
1. `brew install jq`
1. `brew install kafkacat`
1. `brew install coreutils` (I like to use `grealpath`)
1. Install Python 3 <https://www.python.org/downloads/> 
    * `sudo pip3 install --upgrade pip`
    * Add user-installed Python packages to the `PATH` by adding this line in `.bash_profile`: `export PATH="$PATH:/Users/davidgroomes/Library/Python/3.8/bin"`
1. Install the "powerline" status line <https://powerline.readthedocs.io/en/master/installation/osx.html>
    * `pip3 install --user powerline-status`
    * Add initialization commands to your `.bashrc`. Follow <https://powerline.readthedocs.io/en/master/usage/shell-prompts.html#bash-prompt>
    * Do the fonts installation `git clone https://github.com/powerline/fonts.git; cd fonts; ./install.sh`
    * Restart iTerm2, configure "Use a different font for non-ASCII text" and choose the DejaVu font to get the Powerline arrow symbols
    * Start a custom config.json by starting with a copy of the base config:
        * `mkdir -p ~/.config/powerline`
        * `cp /Users/davidgroomes/Library/Python/3.8/lib/python/site-packages/powerline/config_files/config.json ~/.config/powerline`
        * Change the "shell" "theme" from "default" to "default_leftonly" to get the current Git branch stuff in the 
          status line (see <https://github.com/powerline/powerline/issues/186>)
        * You will have to restart the powerline daemon for the config change to take effect: `powerline-daemon --replace`  
1. Add `~/.inputrc`
1. Install bash completion for `pip`: `pip3 completion --bash > /usr/local/etc/bash_completion.d/pip`
1. Install SDKMAN <https://sdkman.io/>
    * Install Graal `sdk install java <latest Graal>`
    * Use Graal `sdk use java <<latest Graal>`
    * Install a community provided Bash completion for SDKMAN `curl https://raw.githubusercontent.com/Bash-it/bash-it/ac5a8aca47f42c6feab6bde3fb7e5a06d53f28ff/completion/available/sdkman.completion.bash -o /usr/local/etc/bash_completion.d/sdkman`
    * Because Graal comes with npm, we can install bash completion for npm with `npm completion > /usr/local/etc/bash_completion.d/npm` 
    * Install Java 8, 11, and 14
    * Install `visualvm` and then configure visualvm to use the Java 8.
      * Follow the instructions at <https://gist.github.com/gavvvr/c9891684f9ef062502d58c80903be5cc>
      * Specifically, edit the file `~/.sdkman/candidates/visualvm/current/etc/visualvm.conf` 
1. Install `nvm` Node Version Manager <https://github.com/nvm-sh/nvm>
    * Install the latest Long-Term Support version of node with `nvm install --lts`
    * Install npx Bash completion from this cool person's completion script `https://gist.github.com/gibatronic/44073260ffdcbd122e9520756c8e35a1`
      Just save it to `/usr/local/etc/bash_completion.d/npx`
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
    * Configure `git` credentials to Github. Follow <https://help.github.com/en/github/authenticating-to-github/accessing-github-using-two-factor-authentication#using-two-factor-authentication-with-the-command-line>
    * Use credentials helper <https://help.github.com/en/github/using-git/caching-your-github-password-in-git>
      * `git config --global credential.helper osxkeychain`
      * The next time you `git push` you will get a popup. Enter your password and choose "Always allow"
1. Install Xcode from the app store
1. Install Rectangle <https://github.com/rxhanson/Rectangle> for fast and easy window resizing
    * Uncheck all keyboard shortcuts. Configure the following:
        * "Left Half": `Ctrl + [`
        * "Right Half": `Ctrl + ]`
        * "Maximize": `Ctrl + \`
1. Install Docker <https://hub.docker.com/editions/community/docker-ce-desktop-mac/>
    * Install Bash completion for `docker`: `curl https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker -o /usr/local/etc/bash_completion.d/bash`
    * Install Bash completion for `docker-compose`: `curl https://raw.githubusercontent.com/docker/compose/1.25.4/contrib/completion/bash/docker-compose -o /usr/local/etc/bash_completion.d/docker-compose` 
1. Install Karabiner-Elements from source <https://github.com/pqrs-org/Karabiner-Elements> and configure it with:
    * `mkdir -p ~/.config/karabiner/assets/complex_modifications`
    * `cp karabiner/karabiner.json ~/.config/karabiner`
    * `cp karabiner/assets/complex_modifications/* ~/.config/karabiner/assets/complex_modifications`
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