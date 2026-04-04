const DIR = path self | path dirname

const VCS_FILENAME = "karabiner.json"
const INSTALLED_FILENAME = "karabiner.json"
const BACKUP_SUCCESS_MSG = "Main 'karabiner.json' configuration file backed up."
const INSTALL_SUCCESS_MSG = "Main 'karabiner.json' configuration file installed."
const UPSTREAM_SUCCESS_MSG = "Main 'karabiner.json' configuration file upstreamed."

def err [msg] {
    error make --unspanned { msg: $msg }
}

def installed-file-path [] {
    [$env.HOME ".config" "karabiner" $INSTALLED_FILENAME] | path join
}

def vcs-file-path [] {
    [(pwd) $VCS_FILENAME] | path join
}

# Create a backup-style filename using the current date and time.
def bak-name-now [filename] {
    [$filename . (date now | format date "%Y-%m-%d-%H-%M-%S") .bak] | str join
}

export def backup [] {
    cd $DIR

    let installed_file_path = installed-file-path
    if (not ($installed_file_path | path exists)) { return }

    let backup_name = bak-name-now $installed_file_path
    mv $installed_file_path $backup_name
    print $BACKUP_SUCCESS_MSG
}

export def install [] {
    cd $DIR

    let installed_file_path = installed-file-path
    if ($installed_file_path | path exists) {
        err $"A configuration file is already installed at '($installed_file_path)'. You must back it up first."
    }

    let vcs_file_path = vcs-file-path
    if (not ($vcs_file_path | path exists)) {
        err $"The configuration file '($vcs_file_path)' does not exist."
    }

    mkdir ($installed_file_path | path dirname)
    cp $vcs_file_path $installed_file_path
    print $INSTALL_SUCCESS_MSG
}

export def upstream [] {
    cd $DIR

    let installed_file_path = installed-file-path
    let vcs_file_path = vcs-file-path

    if not ($installed_file_path | path exists) {
        err $"Config file ($installed_file_path) does not exist"
    }

    cp --force $installed_file_path $vcs_file_path
    print $UPSTREAM_SUCCESS_MSG
}
