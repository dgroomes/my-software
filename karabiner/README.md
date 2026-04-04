# karabiner

My configuration for [Karabiner-Elements][karabiner-elements].


## Instructions

Follow these instructions to back up, install, or upstream the Karabiner configuration files.

1. Activate the Nushell `do` module with the following command.
    - ```nushell
      overlay use --prefix do.nu
      ```
2. Back up the installed Karabiner config file. This backs up `~/.config/karabiner/karabiner.json`
   to a timestamped `.bak` filename if the file exists.
    - ```nushell
      do backup karabiner
      ```
3. Install the version-controlled Karabiner config file into `~/.config/karabiner/` with the following command.
    - ```nushell
      do install karabiner
      ```
4. Upstream the installed Karabiner file back into this repository with the following command.
    - ```nushell
      do upstream karabiner
      ```


## Reference

- [Karabiner-Elements][karabiner-elements]

[karabiner-elements]: https://github.com/pqrs-org/Karabiner-Elements
