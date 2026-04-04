const DIR = path self | path dirname

const config_registry = {
    karabiner: {
        vcs_filename: "karabiner.json"
        installed_filename: "karabiner.json"
        backup_success_msg: "Main 'karabiner.json' configuration file backed up."
        install_success_msg: "Main 'karabiner.json' configuration file installed."
        upstream_success_msg: "Main 'karabiner.json' configuration file upstreamed."
    }
}

def err [msg] {
    error make --unspanned { msg: $msg }
}

def config_names [] {
    $config_registry | transpose key | get key
}

def installed-file-path [config] {
    [$env.HOME ".config" "karabiner" $config.installed_filename] | path join
}

def vcs-file-path [config] {
    [(pwd) $config.vcs_filename] | path join
}

# Create a backup-style filename using the current date and time.
def bak-name-now [filename] {
    [$filename . (date now | format date "%Y-%m-%d-%H-%M-%S") .bak] | str join
}

export def backup [name: string@config_names] {
    cd $DIR

    let config = $config_registry | get $name
    let installed_file_path = installed-file-path $config
    if (not ($installed_file_path | path exists)) { return }

    let backup_name = bak-name-now $installed_file_path
    mv $installed_file_path $backup_name
    print $config.backup_success_msg
}

export def install [name: string@config_names] {
    cd $DIR

    let config = $config_registry | get $name
    let installed_file_path = installed-file-path $config
    if ($installed_file_path | path exists) {
        err $"A configuration file is already installed at '($installed_file_path)'. You must back it up first."
    }

    let vcs_file_path = vcs-file-path $config
    if (not ($vcs_file_path | path exists)) {
        err $"The configuration file '($vcs_file_path)' does not exist."
    }

    mkdir ($installed_file_path | path dirname)
    cp $vcs_file_path $installed_file_path
    print $config.install_success_msg
}

export def upstream [name: string@config_names] {
    cd $DIR

    let config = $config_registry | get $name
    let installed_file_path = installed-file-path $config
    let vcs_file_path = vcs-file-path $config

    if not ($installed_file_path | path exists) {
        err $"Config file ($installed_file_path) does not exist"
    }

    cp --force $installed_file_path $vcs_file_path
    print $config.upstream_success_msg
}
