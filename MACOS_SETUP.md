# My macOS setup

1. Install Homebrew <https://brew.sh/>
1. `brew install bash`
    * macOS uses a years old version of Bash and will never update it because of licensing
    * After installing from Homebrew, you will need to change the default shell with the following.:
    * `sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells'`
    * `chsh -s /usr/local/bin/bash`
    * Open a new session and verify the new version of Bash is being used `echo $BASH_VERSION`
1. `brew install jq`
1. `brew install kafkacat`
1. `brew install coreutils` (I like use `grealpath`)