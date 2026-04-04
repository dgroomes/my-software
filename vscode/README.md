# vscode

My Visual Studio Code user configuration.


## Instructions

Follow these instructions to back up, install, or upstream the VS Code user config files.

1. Activate the Nushell `do` module with the following command.
    - ```nushell
      overlay use --prefix do.nu
      ```
2. Back up an installed VS Code config file from `~/Library/Application Support/Code/User/`. For example, use the following command.
    - ```nushell
      do backup settings
      ```
3. Install a version-controlled VS Code config file into `~/Library/Application Support/Code/User/`.
    - ```nushell
      do install keybindings
      ```
4. Upstream an installed VS Code config file back into this repository.
    - ```nushell
      do upstream settings
      ```


## Reference

- [Visual Studio Code][vscode]

[vscode]: https://code.visualstudio.com/