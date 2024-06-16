# This script is designed to bootstrap a fresh installation of Nushell with my personal configuration. Similarly, it
# helps to re-install the configuration and backup the current configuration.

const config_registry = {
    env: {
        filename: "env.nu"
        backup_success_msg: "Environment configuration file backed up."
        install_success_msg: "Environment configuration file installed."
    }
    standard: {
        filename: "config.nu"
        backup_success_msg: "Standard configuration file backed up."
        install_success_msg: "Standard configuration file installed."
    }
    atuin: {
        filename: "atuin.nu"
        backup_success_msg: "Atuin configuration file backed up."
        install_success_msg: "Atuin configuration file installed."
    }
    core: {
        filename: "core.nu"
        backup_success_msg: "Core configuration file backed up."
        install_success_msg: "Core configuration file installed."
    }
    open_jdk: {
        filename: "open-jdk.nu"
        backup_success_msg: "OpenJDK configuration file backed up."
        install_success_msg: "OpenJDK configuration file installed."
    }
    starship: {
        filename: "starship.nu",
        backup_success_msg: "Starship configuration file backed up."
        install_success_msg: "Starship configuration file installed."
    }
    nu_scripts_sourcer: {
        filename: "nu-scripts-sourcer.nu"
        backup_success_msg: "'nushell/nu_scripts' sourcer file backed up."
    }
}

def config_names [] {
    $config_registry | transpose key | get key
}

export def backup [name: string@config_names] {
    let config = $config_registry | get $name
    let installed_file_path = [$nu.default-config-dir $config.filename] | path join
    if (not ($installed_file_path | path exists)) { return }

    let backup_name = bak_name_now $installed_file_path
    mv $installed_file_path $backup_name
    print $config.backup_success_msg
}

# Back up a Nushell configuration file like the standard configuration file ('config.nu') or one of the other
# configuration files I manage ('atuin.nu').
export def backup_all [] {
    $config_registry | transpose key | each { backup $in.key }
}

# Install a configuration file.
export def main [name: string@config_names, nu_scripts_dir?: string] {
    let config = $config_registry | get $name
    let installed_file_path = [$nu.default-config-dir $config.filename] | path join
    if ($installed_file_path | path exists) {
        error make {
          msg: $"A configuration file is already installed at '($installed_file_path)'. You must back it up first.",
        }
    }

    if ($name == "nu_scripts_sourcer") {
        install_nu_scripts_sourcer $installed_file_path $nu_scripts_dir
        return
    }

    let vcs_file_path = [(pwd) $config.filename] | path join
    if (not ($vcs_file_path | path exists)) {
        error make {
          msg: $"The configuration file '($vcs_file_path)' does not exist.",
        }
    }

    cp $vcs_file_path $installed_file_path
    print $config.install_success_msg
}

export def install_all [] {
    $config_registry | transpose key | each { main $in.key }
}

# Create a backup-style filename using a the current date and time. For example, when you want to backup a file
# like 'my-file.txt', use this command to create the name 'my-file.2024-01-02-00-01-02.bak'.
def bak_name_now [filename] {
    [$filename . (date now | format date "%Y-%m-%d-%H-%M-%S") .bak] | str join
}


# There are many custom completion scripts and other neat scripts in the official "nu_scripts" repository: https://github.com/nushell/nu_scripts/tree/4eab7ea772f0a288c99a79947dd332efc1884315
# We need to generate a script that hardcodes the file paths to a local clone of that repository. This script will source
# the scripts from the local clone. The script is named "nu-scripts-sourcer.nu".
def install_nu_scripts_sourcer [installed_file_path nu_scripts_dir?] {
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
        "git/git-completions.nu",
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
export def install_one_shot_bash_completion [] {
    let script_name = "one-shot-bash-completion.bash"
    let vcs_file_path = [(pwd) $script_name] | path join
    let installed_file_path = [$nu.default-config-dir $script_name] | path join
    cp $vcs_file_path $installed_file_path
}
