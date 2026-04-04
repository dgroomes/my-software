# karabiner

My configuration for [Karabiner-Elements][karabiner-elements].


## Instructions

Follow these instructions to back up, install, or upstream the Karabiner configuration files.

1. Activate the Nushell `do` module with the following command.
    - ```nushell
      overlay use --prefix do.nu
      ```
2. Back up the installed Karabiner files. This backs up `~/.config/karabiner/karabiner.json` and each installed complex
   modification file to a timestamped `.bak` filename if the file exists.
    - ```nushell
      do backup all
      ```
3. Install the version-controlled Karabiner files into `~/.config/karabiner/` with the following command.
    - ```nushell
      do install all
      ```
4. Upstream the installed Karabiner files back into this repository with the following command.
    - ```nushell
      do upstream all
      ```
5. Operate on individual configuration files as needed.
    - For example, back up only the main `karabiner.json` file with the following command.
    - ```nushell
      do backup karabiner
      ```
    - Install only the `move-between-words` complex modification with the following command.
    - ```nushell
      do install move-between-words
      ```
    - Upstream only the `modal-mode` complex modification with the following command.
    - ```nushell
      do upstream modal-mode
      ```


## Reference

- [Karabiner-Elements][karabiner-elements]

[karabiner-elements]: https://github.com/pqrs-org/Karabiner-Elements
