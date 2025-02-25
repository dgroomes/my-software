use zdu.nu err

# 'bcl' stands for 'bash-completer-log'
#
# Print debugging is a simple savior.
def bcl [msg: string] {
    $msg | save --append ~/.nushell-bash-completer.log
    (char newline) | save --append ~/.nushell-bash-completer.log
}

# This is designed to be used as an "external completer" (https://www.nushell.sh/cookbook/external_completers.html)
# based on Bash and the 'bash-completion' library (https://github.com/scop/bash-completion).
export def bash-complete [spans: list<string>] {
    let bash_path = which bash | if ($in | is-empty) {
        # Note: you won't see this message when the closure is invoked by Nushell's external completers machinery.
        # Silencing (or "swallowing") the output of a rogue completer is designed as a feature. Totally fair, but that
        # makes debugging external completer closures difficult. See the 'bash-complete' function which is designed to
        # wrap this closure, which let's you see output like this normally. I didn't have any luck with the standard
        # library logger or the internal logs (e.g. `nu --log-level debug`) either.
        print "Bash is not installed. The Bash completer will not be registered."
        return
    } else {
       $in.0.path
    }

    let one_shot_bash_completion_script = [$nu.default-config-dir one-shot-bash-completion.bash] | path join | if ($in | path exists)  {
        $in | path expand
    } else {
        print "The one-shot Bash completion script does not exist. No completions will be available."
        return
    }

    let line = $spans | str join " "

    # We set up a controlled environment so we have a better chance to debug completion problems. In particular, we are
    # exercising control over the "search order" that 'bash-completion' uses to find completion definitions. For more
    # context, see this section of the 'bash-completion' README: https://github.com/scop/bash-completion/blob/07605cb3e0a3aca8963401c8f7a8e7ee42dbc399/README.md?plain=1#L333
    mut env_vars = {
        BASH_COMPLETION_INSTALLATION_DIR: /opt/homebrew/opt/bash-completion@2
        BASH_COMPLETION_USER_DIR: ([$env.HOME .local/share/bash-completion] | path join)
        BASH_COMPLETION_COMPAT_DIR: /disable-legacy-bash-completions-by-pointing-to-a-dir-that-does-not-exist
        XDG_DATA_DIRS: /opt/homebrew/share
    }

    mut env_vars_path = []

    # Homebrew's 'brew' command comes with an odd implementation of its completion scripts. It relies on the
    # "HOMEBREW_" environment variables that are set up in the 'brew shellenv' command. See https://github.com/Homebrew/brew/blob/e2b2582151d451d078e9df35a23eef00f4d308b3/completions/bash/brew#L111
    # And it relies on grep.
    #
    # So, let's pass the 'HOMEBREW_REPOSITORY' environment variable through and let's make sure 'grep' is on the PATH.
    if ($env.HOMEBREW_REPOSITORY? | is-not-empty) {
        $env_vars = $env_vars | insert HOMEBREW_REPOSITORY $env.HOMEBREW_REPOSITORY
    }

    $env_vars_path = ($env_vars_path | append (which grep | $in.0?.path | path dirname))

    # Homebrew's completion for things like "brew uninstall " will execute 'brew' so that it can list out your installed
    # packages. 'brew' requires the HOME environment for some reason. If you omit it, you'll get the error message
    # "$HOME must be set to run brew.".
    #
    # Also, and I couldn't debug why, but '/bin' needs to be on the PATH as well. Seems reasonable enough.

    $env_vars = ($env_vars | insert HOME $env.HOME)
    $env_vars_path = ($env_vars_path | append "/bin")

    # In its completion lookup logic, 'bash-completion' considers the full path of the command being completed.
    # For example, if the command is 'pipx', then 'bash-completion' tries to resolve ' pipx' to a location on the PATH
    # by issuing a 'type -P -- pipx' command (https://github.com/scop/bash-completion/blob/07605cb3e0a3aca8963401c8f7a8e7ee42dbc399/bash_completion#L3158).
    # It's rare that this is needed to make completions work, but I found it was needed for 'pipx', at least. Do the
    # 'pipx' completions definitions code to an absolute path? Seems like a strange implementation. I'd be curious to
    # learn more.
    #
    # So, we can't isolate the PATH entirely from the one-shot Bash completion script. Let's create a PATH that just
    # contains the directory of the command being completed.
    $env_vars_path = ($env_vars_path | append ($spans.0? | which $in | get path | path dirname))

    let path = ($env_vars_path | str join ":")
    $env_vars = ($env_vars | insert PATH $path)

    # Turn the environment variables into "KEY=VALUE" strings in preparation for the 'env' command.
    mut env_var_args = $env_vars | items { |key, value| [$key "=" $value] | str join }

#    bcl $"env_var_args: ($env_var_args)"

    # Note: we are using "$bash_path" which is the absolute path to the Bash executable of the Bash that's installed
    # via Homebrew. If we were to instead use "bash", then it would resolve to the "bash" that's installed by macOS
    # which is too old to work with 'bash-completion'.
    let result = env -i ...$env_var_args $bash_path --noprofile $one_shot_bash_completion_script $line | complete

#    bcl $"result: ($result)"

    # The one-shot Bash completion script will exit with a 127 exit code if it found no completion definition for the
    # command. This is a normal case, because of course many commands don't have or need completion definitions. At
    # this point, we can't just return an empty list because that would be interpreted by Nushell as "completion options
    # were found to be empty", and the Nushell command line would show "NO RECORDS FOUND". We don't want that. We want
    # Nushell to fallback to file completion. For example, we want "cat " to show the files and directories in the
    # current directory.
    #
    # A null return value tells Nushell to fallback to file completion.
    if ($result.exit_code == 127) {
        return null
    }

    if ($result.exit_code != 0) {
        err $"Something unexpected happened while running the one-shot Bash completion.\n ($result.stderr)"
    }

    # There are a few data quality problems with the completions produced by the Bash script. It's important to note
    # that the Bash completion functions are able to produce anything they want. I've found that the completions for
    # 'git' return duplicates when I do "git switch ". For example, for a repository that only has one branch ("main"),
    # the completion scripts produce "main" twice. I only see that in my non-interactive flow, and I'm taking a wild
    # guess that Bash has some presentation logic that actually de-duplicates (and sorts?) completions before presenting
    # them to the user. Nushell does not do de-duplication of completions (totally fair).
    #
    # Another problem is the trailing newline produced by the Bash script. In general, you just need to be careful with
    # the characters present in completion suggestions because Nushell seems to just let it fly. So a newline really
    # messes things up.
    #
    # The serialization/deserialization of the generated completions from the Bash process to the Nushell process is a
    # bit naive. Consider unhandled cases.
    $result.stdout | split row (char newline) | where $it != '' | sort | uniq
}
