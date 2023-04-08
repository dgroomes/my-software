# My strategy in the .bash_profile is to "do nothing" except delegate to sourcing my .bashrc. The .bashrc itself is generated
# from 'bb' (the ".bashrc bundler"). The .bash_profile is still available for making changes but for the most part I can
# manage my "shell initialization stuff" in individual files in the directory "$HOME/.config/bash" and then bundle it
# with 'bb'.

. "$HOME/.bashrc"
