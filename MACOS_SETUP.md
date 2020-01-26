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
1. Install powerline <https://powerline.readthedocs.io/en/master/installation/osx.html> `pip3 install --user powerline-status`
1. Add `~/.inputrc`