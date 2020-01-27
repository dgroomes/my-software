# My macOS setup

1. Install Homebrew <https://brew.sh/>
1. `brew install bash`
    * macOS uses a years old version of Bash and will never update it because of licensing
    * After installing from Homebrew, you will need to change the default shell with the following.:
    * `sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'`
    * `chsh -s /usr/local/bin/bash`
    * Open a new session and verify the new version of Bash is being used `echo $BASH_VERSION`
1. `brew install bash-completion@2`
    * Add `[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"` to `~/.bash_profile`
    * <https://github.com/Homebrew/homebrew-core/blob/fecd9b0cb2aa855ec24c109ff2b4507c0b37fb2a/Formula/bash-completion%402.rb#L36>
1. `brew install jq`
1. `brew install kafkacat`
1. `brew install coreutils` (I like to use `grealpath`)
1. Install Python 3 <https://www.python.org/downloads/> 
    * `pip3 install --upgrade pip`
    * Add user-installed Python packages to the `PATH` by adding this line in `.bash_profile`: `export PATH="$PATH:/Users/davidgroomes/Library/Python/3.8/bin"`
1. Install powerline <https://powerline.readthedocs.io/en/master/installation/osx.html> `pip3 install --user powerline-status`
    * Do the fonts installation `git clone https://github.com/powerline/fonts.git; cd fonts; ./install.sh`
    * Restart iTerm2, configure "Use a different font for non-ASCII text" and choose the DejaVu font to get the Powerline arrow symbols
1. Add `~/.inputrc`
1. Install bash completion for `pip`: `pip3 completion --bash > /usr/local/etc/bash_completion.d/pip`