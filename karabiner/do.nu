const DIR = path self | path dirname

const config_registry = {
    karabiner: {
        vcs_filename: "karabiner.json"
        installed_filename: "karabiner.json"
        backup_success_msg: "Main 'karabiner.json' configuration file backed up."
        install_success_msg: "Main 'karabiner.json' configuration file installed."
        upstream_success_msg: "Main 'karabiner.json' configuration file upstreamed."
    }
    escape: {
        vcs_filename: "assets/complex_modifications/escape.json"
        installed_filename: "assets/complex_modifications/escape.json"
        backup_success_msg: "The 'escape' complex modification file backed up."
        install_success_msg: "The 'escape' complex modification file installed."
        upstream_success_msg: "The 'escape' complex modification file upstreamed."
    }
    forward-delete: {
        vcs_filename: "assets/complex_modifications/forward-delete.json"
        installed_filename: "assets/complex_modifications/forward-delete.json"
        backup_success_msg: "The 'forward-delete' complex modification file backed up."
        install_success_msg: "The 'forward-delete' complex modification file installed."
        upstream_success_msg: "The 'forward-delete' complex modification file upstreamed."
    }
    hjkl-arrows: {
        vcs_filename: "assets/complex_modifications/hjkl-arrows.json"
        installed_filename: "assets/complex_modifications/hjkl-arrows.json"
        backup_success_msg: "The 'hjkl-arrows' complex modification file backed up."
        install_success_msg: "The 'hjkl-arrows' complex modification file installed."
        upstream_success_msg: "The 'hjkl-arrows' complex modification file upstreamed."
    }
    modal-mode: {
        vcs_filename: "assets/complex_modifications/modal-mode.json"
        installed_filename: "assets/complex_modifications/modal-mode.json"
        backup_success_msg: "The 'modal-mode' complex modification file backed up."
        install_success_msg: "The 'modal-mode' complex modification file installed."
        upstream_success_msg: "The 'modal-mode' complex modification file upstreamed."
    }
    move-between-words: {
        vcs_filename: "assets/complex_modifications/move-between-words.json"
        installed_filename: "assets/complex_modifications/move-between-words.json"
        backup_success_msg: "The 'move-between-words' complex modification file backed up."
        install_success_msg: "The 'move-between-words' complex modification file installed."
        upstream_success_msg: "The 'move-between-words' complex modification file upstreamed."
    }
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

export def "backup all" [] {
    for name in (config_names) {
        backup $name
    }
}

export def install [name: string@config_names] {
    cd $DIR

    let config = $config_registry | get $name
    let installed_file_path = installed-file-path $config
    if ($installed_file_path | path exists) {
        error make {msg: $"A configuration file is already installed at '($installed_file_path)'. You must back it up first."}
    }

    let vcs_file_path = vcs-file-path $config
    if (not ($vcs_file_path | path exists)) {
        error make {msg: $"The configuration file '($vcs_file_path)' does not exist."}
    }

    mkdir ($installed_file_path | path dirname)
    cp $vcs_file_path $installed_file_path
    print $config.install_success_msg
}

export def "install all" [] {
    for name in (config_names) {
        install $name
    }
}

export def upstream [name: string@config_names] {
    cd $DIR

    let config = $config_registry | get $name
    let installed_file_path = installed-file-path $config
    let vcs_file_path = vcs-file-path $config

    if not ($installed_file_path | path exists) {
        error make {msg: $"Config file ($installed_file_path) does not exist"}
    }

    cp --force $installed_file_path $vcs_file_path
    print $config.upstream_success_msg
}

export def "upstream all" [] {
    for name in (config_names) {
        upstream $name
    }
}