# This script is designed to bootstrap a fresh installation of Nushell with my personal configuration. Similarly, it
# helps to re-install the configuration and backup the current configuration.

const config_registry = {
    config: {
        filename: "config.nu"
        backup_success_msg: "Main 'config.nu' configuration file backed up."
        install_success_msg: "Main 'config.nu' configuration file installed."
    }
    atuin: {
        filename: "vendor/autoload/atuin.nu"
        backup_success_msg: "Atuin configuration file backed up."
        install_success_msg: "Atuin configuration file installed."
    }
    bash_completer: {
        filename: "scripts/bash-completer.nu"
        backup_success_msg: "Bash completer library file backed up."
        install_success_msg: "Bash completer library file installed."
    }
    file_set: {
        filename: "scripts/file-set.nu"
        backup_success_msg: "'file-set' library file backed up."
        install_success_msg: "'file-set' library file installed."
    }
    lib: {
        filename: "scripts/lib.nu"
        backup_success_msg: "Library file backed up."
        install_success_msg: "Library file installed."
    }
    node: {
        filename: "scripts/node.nu"
        backup_success_msg: "Node.js library file backed up."
        install_success_msg: "Node.js library file installed."
    }
    open_jdk: {
        filename: "scripts/open-jdk.nu"
        backup_success_msg: "OpenJDK library file backed up."
        install_success_msg: "OpenJDK library file installed."
    }
    postgres: {
        filename: "scripts/postgres.nu"
        backup_success_msg: "Postgres lib file backed up."
        install_success_msg: "Postgres lib file installed."
    }
    starship: {
        filename: "vendor/autoload/starship.nu",
        backup_success_msg: "Starship configuration file backed up."
        install_success_msg: "Starship configuration file installed."
    }
    nu_scripts_sourcer: {
        filename: "vendor/autoload/nu-scripts-sourcer.nu"
        backup_success_msg: "'nushell/nu_scripts' sourcer file backed up."
    }
    zoxide: {
        filename: "vendor/autoload/zoxide.nu"
        backup_success_msg: "zoxide configuration file backed up."
        install_success_msg: "zoxide configuration file installed."
    }
    zdu: {
        filename: "scripts/zdu.nu"
        backup_success_msg: "Zero-deps-utility lib file backed up."
        install_success_msg: "Zero-deps-utility lib file installed."
    }
}

def config_names [] {
    $config_registry | transpose key | get key
}

export def "backup" [name: string@config_names] {
    cd $env.DO_DIR

    let config = $config_registry | get $name
    let installed_file_path = [$nu.default-config-dir $config.filename] | path join
    if (not ($installed_file_path | path exists)) { return }

    let backup_name = bak_name_now $installed_file_path
    mv $installed_file_path $backup_name
    print $config.backup_success_msg
}

# Install a configuration file.
export def "install" [name: string@config_names, nu_scripts_dir?: string] {
    cd $env.DO_DIR

    let config = $config_registry | get $name
    let installed_file_path = [$nu.default-config-dir $config.filename] | path join
    if ($installed_file_path | path exists) {
        error make --unspanned {
          msg: $"A configuration file is already installed at '($installed_file_path)'. You must back it up first.",
        }
    }

    if ($name == "nu_scripts_sourcer") {
        install-nu-scripts-sourcer $installed_file_path $nu_scripts_dir
        return
    }

    let vcs_file_path = [(pwd) $config.filename] | path join
    if (not ($vcs_file_path | path exists)) {
        error make {
          msg: $"The configuration file '($vcs_file_path)' does not exist.",
        }
    }

    # Create the containing directory if it doesn't exist. For example, accommodate the 'setup/' directory.
    mkdir ($installed_file_path | path dirname)
    cp $vcs_file_path $installed_file_path
    print $config.install_success_msg
}

# Create a backup-style filename using a the current date and time. For example, when you want to backup a file
# like 'my-file.txt', use this command to create the name 'my-file.2024-01-02-00-01-02.bak'.
def bak_name_now [filename] {
    [$filename . (date now | format date "%Y-%m-%d-%H-%M-%S") .bak] | str join
}


# There are many custom completion scripts and other neat scripts in the official "nu_scripts" repository: https://github.com/nushell/nu_scripts/tree/4eab7ea772f0a288c99a79947dd332efc1884315
# We need to generate a script that hardcodes the file paths to a local clone of that repository. This script will source
# the scripts from the local clone. The script is named "nu-scripts-sourcer.nu".
def install-nu-scripts-sourcer [installed_file_path nu_scripts_dir?] {
    cd $env.DO_DIR

    if ($nu_scripts_dir == null) {
        # There's nothing to source. In this case, you may have a fresh install of Nu and you haven't cloned the
        # 'nu_scripts' repository yet.
        print "Blank 'nu-scripts-sourcer.nu' file created."
        touch $installed_file_path
        return
    }

    if (not ($nu_scripts_dir | path exists)) {
        error make {
          msg: $"The directory '($nu_scripts_dir)' does not exist.",
        }
    }

    let completion_short_paths = [
        # The completions for 'git checkout ' don't yield values of tags. I think I've run into some other missing cases
        # too. I'm happy to just use Bash completion for 'git'.
        # "git/git-completions.nu",

        "gh/gh-completions.nu"
        "cargo/cargo-completions.nu"
        "less/less-completions.nu"
        "make/make-completions.nu"
        "npm/npm-completions.nu"
        "poetry/poetry-completions.nu"
        "rg/rg-completions.nu"
        "rustup/rustup-completions.nu"
        "tar/tar-completions.nu"
    ]

    let source_lines = $completion_short_paths | each { |it|
        let path = [$nu_scripts_dir custom-completions $it ] | path join
        if (not ($path | path exists)) {
            error make {
              msg: $"The completion script '($path)' does not exist.",
            }
        }
        let abs_path = $path | path expand
        $'source "($abs_path)"'
    }

    let source_block = $source_lines | str join (char newline) | $in + (char newline)
    $source_block | save --raw $installed_file_path
    print $"'nu_scripts' sourcer file generated and using ($completion_short_paths | length) completion scripts."
}

# Install the one-shot Bash completion script. I'm not bothering supporting the "backup" flow for this script because
# I don't have a reason to edit it. If I need to add features or implement bug fixes I would do that in the version
# controlled file.
export def "install-one-shot-bash-completion" [] {
    cd $env.DO_DIR

    let script_name = "one-shot-bash-completion.bash"
    let vcs_file_path = [(pwd) $script_name] | path join
    let installed_file_path = [$nu.default-config-dir $script_name] | path join
    cp $vcs_file_path $installed_file_path
}
