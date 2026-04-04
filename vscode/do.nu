const DIR = path self | path dirname
const CONFIG_REGISTRY = {
    settings: {
        filename: "settings.json"
        backup_success_msg: "VS Code 'settings.json' backed up."
        install_success_msg: "VS Code 'settings.json' installed."
        upstream_success_msg: "VS Code 'settings.json' upstreamed."
    }
    keybindings: {
        filename: "keybindings.json"
        backup_success_msg: "VS Code 'keybindings.json' backed up."
        install_success_msg: "VS Code 'keybindings.json' installed."
        upstream_success_msg: "VS Code 'keybindings.json' upstreamed."
    }
}

def err [msg] {
    error make --unspanned { msg: $msg }
}

def config_names [] {
    $CONFIG_REGISTRY | transpose key | get key
}

def vscode-user-dir [] {
    [$env.HOME "Library" "Application Support" "Code" "User"] | path join
}

def installed-file-path [config] {
    [(vscode-user-dir) $config.filename] | path join
}

def vcs-file-path [config] {
    cd $DIR
    [(pwd) $config.filename] | path join
}

# Create a backup-style filename using the current date and time.
def bak-name-now [filename] {
    [$filename . (date now | format date "%Y-%m-%d-%H-%M-%S") .bak] | str join
}

export def backup [name: string@config_names] {
    cd $DIR

    let config = $CONFIG_REGISTRY | get $name
    let installed_file_path = installed-file-path $config
    if (not ($installed_file_path | path exists)) { return }

    let backup_name = bak-name-now $installed_file_path
    mv $installed_file_path $backup_name
    print $config.backup_success_msg
}

export def install [name: string@config_names] {
    cd $DIR

    let config = $CONFIG_REGISTRY | get $name
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

    let config = $CONFIG_REGISTRY | get $name
    let installed_file_path = installed-file-path $config
    let vcs_file_path = vcs-file-path $config

    if not ($installed_file_path | path exists) {
        err $"Config file ($installed_file_path) does not exist"
    }

    cp --force $installed_file_path $vcs_file_path
    print $config.upstream_success_msg
}