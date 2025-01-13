# I'm referring to this as "core config" because it's mostly just the contents of the default Nushell config file.
#
# version = "0.98.0"

# For more information on defining custom themes, see
# https://www.nushell.sh/book/coloring_and_theming.html
# And here is the theme collection
# https://github.com/nushell/nu_scripts/tree/main/themes
let dark_theme = {
    # color for nushell primitives
    separator: white
    leading_trailing_space_bg: { attr: n } # no fg, no bg, attr none effectively turns this off
    header: green_bold
    empty: blue
    # Closures can be used to choose colors for specific values.
    # The value (in this case, a bool) is piped into the closure.
    # eg) {|| if $in { 'light_cyan' } else { 'light_gray' } }
    bool: light_cyan
    int: white
    filesize: cyan
    duration: white
    date: purple
    range: white
    float: white
    string: white
    nothing: white
    binary: white
    cell-path: white
    row_index: green_bold
    record: white
    list: white
    block: white
    hints: dark_gray
    search_result: { bg: red fg: white }
    shape_and: purple_bold
    shape_binary: purple_bold
    shape_block: blue_bold
    shape_bool: light_cyan
    shape_closure: green_bold
    shape_custom: green
    shape_datetime: cyan_bold
    shape_directory: cyan
    shape_external: cyan
    shape_externalarg: green_bold
    shape_external_resolved: light_yellow_bold
    shape_filepath: cyan
    shape_flag: blue_bold
    shape_float: purple_bold
    # shapes are used to change the cli syntax highlighting
    shape_garbage: { fg: white bg: red attr: b }
    shape_glob_interpolation: cyan_bold
    shape_globpattern: cyan_bold
    shape_int: purple_bold
    shape_internalcall: cyan_bold
    shape_keyword: cyan_bold
    shape_list: cyan_bold
    shape_literal: blue
    shape_match_pattern: green
    shape_matching_brackets: { attr: u }
    shape_nothing: light_cyan
    shape_operator: yellow
    shape_or: purple_bold
    shape_pipe: purple_bold
    shape_range: yellow_bold
    shape_record: cyan_bold
    shape_redirection: purple_bold
    shape_signature: green_bold
    shape_string: green
    shape_string_interpolation: cyan_bold
    shape_table: blue_bold
    shape_variable: purple
    shape_vardecl: purple
    shape_raw_string: light_purple
}

let light_theme = {
    # color for nushell primitives
    separator: dark_gray
    leading_trailing_space_bg: { attr: n } # no fg, no bg, attr none effectively turns this off
    header: green_bold
    empty: blue
    # Closures can be used to choose colors for specific values.
    # The value (in this case, a bool) is piped into the closure.
    # eg) {|| if $in { 'dark_cyan' } else { 'dark_gray' } }
    bool: dark_cyan
    int: dark_gray
    filesize: cyan_bold
    duration: dark_gray
    date: purple
    range: dark_gray
    float: dark_gray
    string: dark_gray
    nothing: dark_gray
    binary: dark_gray
    cell-path: dark_gray
    row_index: green_bold
    record: dark_gray
    list: dark_gray
    block: dark_gray
    hints: dark_gray
    search_result: { fg: white bg: red }
    shape_and: purple_bold
    shape_binary: purple_bold
    shape_block: blue_bold
    shape_bool: light_cyan
    shape_closure: green_bold
    shape_custom: green
    shape_datetime: cyan_bold
    shape_directory: cyan
    shape_external: cyan
    shape_externalarg: green_bold
    shape_external_resolved: light_purple_bold
    shape_filepath: cyan
    shape_flag: blue_bold
    shape_float: purple_bold
    # shapes are used to change the cli syntax highlighting
    shape_garbage: { fg: white bg: red attr: b }
    shape_glob_interpolation: cyan_bold
    shape_globpattern: cyan_bold
    shape_int: purple_bold
    shape_internalcall: cyan_bold
    shape_keyword: cyan_bold
    shape_list: cyan_bold
    shape_literal: blue
    shape_match_pattern: green
    shape_matching_brackets: { attr: u }
    shape_nothing: light_cyan
    shape_operator: yellow
    shape_or: purple_bold
    shape_pipe: purple_bold
    shape_range: yellow_bold
    shape_record: cyan_bold
    shape_redirection: purple_bold
    shape_signature: green_bold
    shape_string: green
    shape_string_interpolation: cyan_bold
    shape_table: blue_bold
    shape_variable: purple
    shape_vardecl: purple
    shape_raw_string: light_purple
}

# External completer example
# let carapace_completer = {|spans|
#     carapace $spans.0 nushell ...$spans | from json
# }

# The default config record. This is where much of your global configuration is setup.
$env.config = {
    show_banner: false # true or false to enable or disable the welcome banner at startup

    ls: {
        use_ls_colors: true # use the LS_COLORS environment variable to colorize output
        clickable_links: true # enable or disable clickable links. Your terminal has to support links.
    }

    rm: {
        always_trash: false # always act as if -t was given. Can be overridden with -p
    }

    table: {
        mode: rounded # basic, compact, compact_double, light, thin, with_love, rounded, reinforced, heavy, none, other
        index_mode: always # "always" show indexes, "never" show indexes, "auto" = show indexes when a table has "index" column
        show_empty: true # show 'empty list' and 'empty record' placeholders for command output
        padding: { left: 1, right: 1 } # a left right padding of each column in a table
        trim: {
            methodology: wrapping # wrapping or truncating
            wrapping_try_keep_words: true # A strategy used by the 'wrapping' methodology
            truncating_suffix: "..." # A suffix used by the 'truncating' methodology
        }
        header_on_separator: false # show header text on separator/border line
        # abbreviated_row_count: 10 # limit data rows from top and bottom after reaching a set point
    }

    error_style: "fancy" # "fancy" or "plain" for screen reader-friendly error messages

    # Whether an error message should be printed if an error of a certain kind is triggered.
    display_errors: {
        exit_code: false # assume the external command prints an error message
        # Core dump errors are always printed, and SIGPIPE never triggers an error.
        # The setting below controls message printing for termination by all other signals.
        termination_signal: true
    }

    # datetime_format determines what a datetime rendered in the shell would look like.
    # Behavior without this configuration point will be to "humanize" the datetime display,
    # showing something like "a day ago."
    datetime_format: {
        # normal: '%a, %d %b %Y %H:%M:%S %z'    # shows up in displays of variables or other datetime's outside of tables
        # table: '%m/%d/%y %I:%M:%S%p'          # generally shows up in tabular outputs such as ls. commenting this out will change it to the default human readable datetime format
    }

    explore: {
        status_bar_background: { fg: "#1D1F21", bg: "#C4C9C6" },
        command_bar_text: { fg: "#C4C9C6" },
        highlight: { fg: "black", bg: "yellow" },
        status: {
            error: { fg: "white", bg: "red" },
            warn: {}
            info: {}
        },
        selected_cell: { bg: light_blue },
    }

    history: {
        max_size: 100_000 # Session has to be reloaded for this to take effect
        sync_on_enter: true # Enable to share history between multiple sessions, else you have to close the session to write history to file
        file_format: "sqlite" # "sqlite" or "plaintext"
        isolation: true # only available with sqlite file_format. true enables history isolation, false disables it. true will allow the history to be isolated to the current session using up/down arrows. false will allow the history to be shared across all sessions.
    }

    completions: {
        case_sensitive: false # set to true to enable case-sensitive completions
        quick: true    # set this to false to prevent auto-selecting completions when only one remains
        partial: true    # set this to false to prevent partial filling of the prompt
        algorithm: "prefix"    # prefix or fuzzy
        sort: "smart" # "smart" (alphabetical for prefix matching, fuzzy score for fuzzy matching) or "alphabetical"
        external: {
            enable: true # set to false to prevent nushell looking into $env.PATH to find more suggestions, `false` recommended for WSL users as this look up may be very slow
            max_results: 100 # setting it lower can improve completion performance at the cost of omitting some options
            completer: null # check 'carapace_completer' above as an example
        }
        use_ls_colors: true # set this to true to enable file/path/directory completions using LS_COLORS
    }

    filesize: {
        metric: false # true => KB, MB, GB (ISO standard), false => KiB, MiB, GiB (Windows standard)
        format: "auto" # b, kb, kib, mb, mib, gb, gib, tb, tib, pb, pib, eb, eib, auto
    }

    cursor_shape: {
        emacs: line # block, underscore, line, blink_block, blink_underscore, blink_line, inherit to skip setting cursor shape (line is the default)
        vi_insert: block # block, underscore, line, blink_block, blink_underscore, blink_line, inherit to skip setting cursor shape (block is the default)
        vi_normal: underscore # block, underscore, line, blink_block, blink_underscore, blink_line, inherit to skip setting cursor shape (underscore is the default)
    }

    color_config: $dark_theme # if you want a more interesting theme, you can replace the empty record with `$dark_theme`, `$light_theme` or another custom record
    footer_mode: 25 # always, never, number_of_rows, auto
    float_precision: 2 # the precision for displaying floats in tables
    buffer_editor: "vim" # command that will be used to edit the current line buffer with ctrl+o, if unset fallback to $env.EDITOR and $env.VISUAL
    use_ansi_coloring: true
    bracketed_paste: true # enable bracketed paste, currently useless on windows
    edit_mode: emacs # emacs, vi
    shell_integration: {
        # osc2 abbreviates the path if in the home_dir, sets the tab/window title, shows the running command in the tab/window title
        osc2: true
        # osc7 is a way to communicate the path to the terminal, this is helpful for spawning new tabs in the same directory
        osc7: true
        # osc8 is also implemented as the deprecated setting ls.show_clickable_links, it shows clickable links in ls output if your terminal supports it. show_clickable_links is deprecated in favor of osc8
        osc8: true
        # osc9_9 is from ConEmu and is starting to get wider support. It's similar to osc7 in that it communicates the path to the terminal
        osc9_9: false
        # osc133 is several escapes invented by Final Term which include the supported ones below.
        # 133;A - Mark prompt start
        # 133;B - Mark prompt end
        # 133;C - Mark pre-execution
        # 133;D;exit - Mark execution finished with exit code
        # This is used to enable terminals to know where the prompt is, the command is, where the command finishes, and where the output of the command is
        osc133: true
        # osc633 is closely related to osc133 but only exists in visual studio code (vscode) and supports their shell integration features
        # 633;A - Mark prompt start
        # 633;B - Mark prompt end
        # 633;C - Mark pre-execution
        # 633;D;exit - Mark execution finished with exit code
        # 633;E - Explicitly set the command line with an optional nonce
        # 633;P;Cwd=<path> - Mark the current working directory and communicate it to the terminal
        # and also helps with the run recent menu in vscode
        osc633: true
        # reset_application_mode is escape \x1b[?1l and was added to help ssh work better
        reset_application_mode: true
    }
    render_right_prompt_on_last_line: false # true or false to enable or disable right prompt to be rendered on last line of the prompt.
    use_kitty_protocol: false # enables keyboard enhancement protocol implemented by kitty console, only if your terminal support this.
    highlight_resolved_externals: false # true enables highlighting of external commands in the repl resolved by which.
    recursion_limit: 50 # the maximum number of times nushell allows recursion before stopping it

    plugins: {} # Per-plugin configuration. See https://www.nushell.sh/contributor-book/plugins.html#configuration.

    plugin_gc: {
        # Configuration for plugin garbage collection
        default: {
            enabled: true # true to enable stopping of inactive plugins
            stop_after: 10sec # how long to wait after a plugin is inactive to stop it
        }
        plugins: {
            # alternate configuration for specific plugins, by name, for example:
            #
            # gstat: {
            #     enabled: false
            # }
        }
    }

    hooks: {
        pre_prompt: [{ null }] # run before the prompt is shown
        pre_execution: [{ null }] # run before the repl input is run
        env_change: {
            PWD: [{|before, after| null }] # run if the PWD environment is different since the last repl input
        }
        display_output: "if (term size).columns >= 100 { table -e } else { table }" # run to display the output of a pipeline
        command_not_found: { null } # return an error message when a command is not found
    }

    menus: [
        # Configuration for default nushell menus
        # Note the lack of source parameter
        {
            name: completion_menu
            only_buffer_difference: false
            marker: "| "
            type: {
                layout: columnar
                columns: 4
                col_width: 20     # Optional value. If missing all the screen width is used to calculate column width
                col_padding: 2
            }
            style: {
                text: green
                selected_text: { attr: r }
                description_text: yellow
                match_text: { attr: u }
                selected_match_text: { attr: ur }
            }
        }
        {
            name: ide_completion_menu
            only_buffer_difference: false
            marker: "| "
            type: {
                layout: ide
                min_completion_width: 0,
                max_completion_width: 50,
                max_completion_height: 10, # will be limited by the available lines in the terminal
                padding: 0,
                border: true,
                cursor_offset: 0,
                description_mode: "prefer_right"
                min_description_width: 0
                max_description_width: 50
                max_description_height: 10
                description_offset: 1
                # If true, the cursor pos will be corrected, so the suggestions match up with the typed text
                #
                # C:\> str
                #      str join
                #      str trim
                #      str split
                correct_cursor_pos: false
            }
            style: {
                text: green
                selected_text: { attr: r }
                description_text: yellow
                match_text: { attr: u }
                selected_match_text: { attr: ur }
            }
        }
        {
            name: history_menu
            only_buffer_difference: true
            marker: "? "
            type: {
                layout: list
                page_size: 10
            }
            style: {
                text: green
                selected_text: green_reverse
                description_text: yellow
            }
        }
        {
            name: help_menu
            only_buffer_difference: true
            marker: "? "
            type: {
                layout: description
                columns: 4
                col_width: 20     # Optional value. If missing all the screen width is used to calculate column width
                col_padding: 2
                selection_rows: 4
                description_rows: 10
            }
            style: {
                text: green
                selected_text: green_reverse
                description_text: yellow
            }
        }
    ]

    keybindings: [
        {
            name: completion_menu
            modifier: none
            keycode: tab
            mode: [emacs vi_normal vi_insert]
            event: {
                until: [
                    { send: menu name: completion_menu }
                    { send: menunext }
                    { edit: complete }
                ]
            }
        }
        {
            name: ide_completion_menu
            modifier: control
            keycode: char_n
            mode: [emacs vi_normal vi_insert]
            event: {
                until: [
                    { send: menu name: ide_completion_menu }
                    { send: menunext }
                    { edit: complete }
                ]
            }
        }
        {
            name: history_menu
            modifier: control
            keycode: char_r
            mode: [emacs, vi_insert, vi_normal]
            event: { send: menu name: history_menu }
        }
        {
            name: help_menu
            modifier: none
            keycode: f1
            mode: [emacs, vi_insert, vi_normal]
            event: { send: menu name: help_menu }
        }
        {
            name: completion_previous_menu
            modifier: shift
            keycode: backtab
            mode: [emacs, vi_normal, vi_insert]
            event: { send: menuprevious }
        }
        {
            name: next_page_menu
            modifier: control
            keycode: char_x
            mode: emacs
            event: { send: menupagenext }
        }
        {
            name: undo_or_previous_page_menu
            modifier: control
            keycode: char_z
            mode: emacs
            event: {
                until: [
                    { send: menupageprevious }
                    { edit: undo }
                ]
            }
        }
        {
            name: escape
            modifier: none
            keycode: escape
            mode: [emacs, vi_normal, vi_insert]
            event: { send: esc }    # NOTE: does not appear to work
        }
        {
            name: cancel_command
            modifier: control
            keycode: char_c
            mode: [emacs, vi_normal, vi_insert]
            event: { send: ctrlc }
        }
        {
            name: quit_shell
            modifier: control
            keycode: char_d
            mode: [emacs, vi_normal, vi_insert]
            event: { send: ctrld }
        }
        {
            name: clear_screen
            modifier: control
            keycode: char_l
            mode: [emacs, vi_normal, vi_insert]
            event: { send: clearscreen }
        }
        {
            name: search_history
            modifier: control
            keycode: char_q
            mode: [emacs, vi_normal, vi_insert]
            event: { send: searchhistory }
        }
        {
            name: open_command_editor
            modifier: control
            keycode: char_o
            mode: [emacs, vi_normal, vi_insert]
            event: { send: openeditor }
        }
        {
            name: move_up
            modifier: none
            keycode: up
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: menuup }
                    { send: up }
                ]
            }
        }
        {
            name: move_down
            modifier: none
            keycode: down
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: menudown }
                    { send: down }
                ]
            }
        }
        {
            name: move_left
            modifier: none
            keycode: left
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: menuleft }
                    { send: left }
                ]
            }
        }
        {
            name: move_right_or_take_history_hint
            modifier: none
            keycode: right
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: historyhintcomplete }
                    { send: menuright }
                    { send: right }
                ]
            }
        }
        {
            name: move_one_word_left
            modifier: control
            keycode: left
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: movewordleft }
        }
        {
            name: move_one_word_right_or_take_history_hint
            modifier: control
            keycode: right
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: historyhintwordcomplete }
                    { edit: movewordright }
                ]
            }
        }
        {
            name: move_to_line_start
            modifier: none
            keycode: home
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: movetolinestart }
        }
        {
            name: move_to_line_start
            modifier: control
            keycode: char_a
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: movetolinestart }
        }
        {
            name: move_to_line_end_or_take_history_hint
            modifier: none
            keycode: end
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: historyhintcomplete }
                    { edit: movetolineend }
                ]
            }
        }
        {
            name: move_to_line_end_or_take_history_hint
            modifier: control
            keycode: char_e
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: historyhintcomplete }
                    { edit: movetolineend }
                ]
            }
        }
        {
            name: move_to_line_start
            modifier: control
            keycode: home
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: movetolinestart }
        }
        {
            name: move_to_line_end
            modifier: control
            keycode: end
            mode: [emacs, vi_normal, vi_insert]
            event: { edit: movetolineend }
        }
        {
            name: move_up
            modifier: control
            keycode: char_p
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: menuup }
                    { send: up }
                ]
            }
        }
        {
            name: move_down
            modifier: control
            keycode: char_t
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    { send: menudown }
                    { send: down }
                ]
            }
        }
        {
            name: delete_one_character_backward
            modifier: none
            keycode: backspace
            mode: [emacs, vi_insert]
            event: { edit: backspace }
        }
        {
            name: delete_one_word_backward
            modifier: control
            keycode: backspace
            mode: [emacs, vi_insert]
            event: { edit: backspaceword }
        }
        {
            name: delete_one_character_forward
            modifier: none
            keycode: delete
            mode: [emacs, vi_insert]
            event: { edit: delete }
        }
        {
            name: delete_one_character_forward
            modifier: control
            keycode: delete
            mode: [emacs, vi_insert]
            event: { edit: delete }
        }
        {
            name: delete_one_character_backward
            modifier: control
            keycode: char_h
            mode: [emacs, vi_insert]
            event: { edit: backspace }
        }
        {
            name: delete_one_word_backward
            modifier: control
            keycode: char_w
            mode: [emacs, vi_insert]
            event: { edit: backspaceword }
        }
        {
            name: move_left
            modifier: none
            keycode: backspace
            mode: vi_normal
            event: { edit: moveleft }
        }
        {
            name: newline_or_run_command
            modifier: none
            keycode: enter
            mode: emacs
            event: { send: enter }
        }
        {
            name: move_left
            modifier: control
            keycode: char_b
            mode: emacs
            event: {
                until: [
                    { send: menuleft }
                    { send: left }
                ]
            }
        }
        {
            name: move_right_or_take_history_hint
            modifier: control
            keycode: char_f
            mode: emacs
            event: {
                until: [
                    { send: historyhintcomplete }
                    { send: menuright }
                    { send: right }
                ]
            }
        }
        {
            name: redo_change
            modifier: control
            keycode: char_g
            mode: emacs
            event: { edit: redo }
        }
        {
            name: undo_change
            modifier: control
            keycode: char_z
            mode: emacs
            event: { edit: undo }
        }
        {
            name: paste_before
            modifier: control
            keycode: char_y
            mode: emacs
            event: { edit: pastecutbufferbefore }
        }
        {
            name: cut_word_left
            modifier: control
            keycode: char_w
            mode: emacs
            event: { edit: cutwordleft }
        }
        {
            name: cut_line_to_end
            modifier: control
            keycode: char_k
            mode: emacs
            event: { edit: cuttolineend }
        }
        {
            name: cut_line_from_start
            modifier: control
            keycode: char_u
            mode: emacs
            event: { edit: cutfromstart }
        }
        {
            name: swap_graphemes
            modifier: control
            keycode: char_t
            mode: emacs
            event: { edit: swapgraphemes }
        }
        {
            name: move_one_word_left
            modifier: alt
            keycode: left
            mode: emacs
            event: { edit: movewordleft }
        }
        {
            name: move_one_word_right_or_take_history_hint
            modifier: alt
            keycode: right
            mode: emacs
            event: {
                until: [
                    { send: historyhintwordcomplete }
                    { edit: movewordright }
                ]
            }
        }
        {
            name: move_one_word_left
            modifier: alt
            keycode: char_b
            mode: emacs
            event: { edit: movewordleft }
        }
        {
            name: move_one_word_right_or_take_history_hint
            modifier: alt
            keycode: char_f
            mode: emacs
            event: {
                until: [
                    { send: historyhintwordcomplete }
                    { edit: movewordright }
                ]
            }
        }
        {
            name: delete_one_word_forward
            modifier: alt
            keycode: delete
            mode: emacs
            event: { edit: deleteword }
        }
        {
            name: delete_one_word_backward
            modifier: alt
            keycode: backspace
            mode: emacs
            event: { edit: backspaceword }
        }
        {
            name: delete_one_word_backward
            modifier: alt
            keycode: char_m
            mode: emacs
            event: { edit: backspaceword }
        }
        {
            name: cut_word_to_right
            modifier: alt
            keycode: char_d
            mode: emacs
            event: { edit: cutwordright }
        }
        {
            name: upper_case_word
            modifier: alt
            keycode: char_u
            mode: emacs
            event: { edit: uppercaseword }
        }
        {
            name: lower_case_word
            modifier: alt
            keycode: char_l
            mode: emacs
            event: { edit: lowercaseword }
        }
        {
            name: capitalize_char
            modifier: alt
            keycode: char_c
            mode: emacs
            event: { edit: capitalizechar }
        }
        # The following bindings with `*system` events require that Nushell has
        # been compiled with the `system-clipboard` feature.
        # If you want to use the system clipboard for visual selection or to
        # paste directly, uncomment the respective lines and replace the version
        # using the internal clipboard.
        {
            name: copy_selection
            modifier: control_shift
            keycode: char_c
            mode: emacs
            event: { edit: copyselection }
            # event: { edit: copyselectionsystem }
        }
        {
            name: cut_selection
            modifier: control_shift
            keycode: char_x
            mode: emacs
            event: { edit: cutselection }
            # event: { edit: cutselectionsystem }
        }
        # {
        #     name: paste_system
        #     modifier: control_shift
        #     keycode: char_v
        #     mode: emacs
        #     event: { edit: pastesystem }
        # }
        {
            name: select_all
            modifier: control_shift
            keycode: char_a
            mode: emacs
            event: { edit: selectall }
        }
    ]
}

# Generated with 'vivid'. See the 'vivid/' directory.
$env.LS_COLORS = "*~=0;38;2;122;112;112:bd=0;38;2;102;217;239;48;2;51;51;51:ca=0:cd=0;38;2;249;38;114;48;2;51;51;51:di=0;38;2;0;141;161:do=0;38;2;0;0;0;48;2;249;38;114:ex=1;38;2;249;38;114:fi=0:ln=0;38;2;249;38;114:mh=0:mi=0;38;2;0;0;0;48;2;255;74;68:no=0:or=0;38;2;0;0;0;48;2;255;74;68:ow=0:pi=0;38;2;0;0;0;48;2;102;217;239:rs=0:sg=0:so=0;38;2;0;0;0;48;2;249;38;114:st=0:su=0:tw=0:*.1=0;38;2;154;143;0:*.a=1;38;2;249;38;114:*.c=0;38;2;0;174;63:*.d=0;38;2;0;174;63:*.h=0;38;2;0;174;63:*.m=0;38;2;0;174;63:*.o=0;38;2;122;112;112:*.p=0;38;2;0;174;63:*.r=0;38;2;0;174;63:*.t=0;38;2;0;174;63:*.v=0;38;2;0;174;63:*.z=4;38;2;249;38;114:*.7z=4;38;2;249;38;114:*.ai=0;38;2;214;119;0:*.as=0;38;2;0;174;63:*.bc=0;38;2;122;112;112:*.bz=4;38;2;249;38;114:*.cc=0;38;2;0;174;63:*.cp=0;38;2;0;174;63:*.cr=0;38;2;0;174;63:*.cs=0;38;2;0;174;63:*.db=4;38;2;249;38;114:*.di=0;38;2;0;174;63:*.el=0;38;2;0;174;63:*.ex=0;38;2;0;174;63:*.fs=0;38;2;0;174;63:*.go=0;38;2;0;174;63:*.gv=0;38;2;0;174;63:*.gz=4;38;2;249;38;114:*.ha=0;38;2;0;174;63:*.hh=0;38;2;0;174;63:*.hi=0;38;2;122;112;112:*.hs=0;38;2;0;174;63:*.jl=0;38;2;0;174;63:*.js=0;38;2;0;174;63:*.ko=1;38;2;249;38;114:*.kt=0;38;2;0;174;63:*.la=0;38;2;122;112;112:*.ll=0;38;2;0;174;63:*.lo=0;38;2;122;112;112:*.ma=0;38;2;214;119;0:*.mb=0;38;2;214;119;0:*.md=0;38;2;154;143;0:*.mk=0;38;2;100;163;0:*.ml=0;38;2;0;174;63:*.mn=0;38;2;0;174;63:*.nb=0;38;2;0;174;63:*.nu=0;38;2;0;174;63:*.pl=0;38;2;0;174;63:*.pm=0;38;2;0;174;63:*.pp=0;38;2;0;174;63:*.ps=0;38;2;230;219;116:*.py=0;38;2;0;174;63:*.rb=0;38;2;0;174;63:*.rm=0;38;2;214;119;0:*.rs=0;38;2;0;174;63:*.sh=0;38;2;0;174;63:*.so=1;38;2;249;38;114:*.td=0;38;2;0;174;63:*.ts=0;38;2;0;174;63:*.ui=0;38;2;100;163;0:*.vb=0;38;2;0;174;63:*.wv=0;38;2;214;119;0:*.xz=4;38;2;249;38;114:*FAQ=0;38;2;0;0;0;48;2;230;219;116:*.3ds=0;38;2;214;119;0:*.3fr=0;38;2;214;119;0:*.3mf=0;38;2;214;119;0:*.adb=0;38;2;0;174;63:*.ads=0;38;2;0;174;63:*.aif=0;38;2;214;119;0:*.amf=0;38;2;214;119;0:*.ape=0;38;2;214;119;0:*.apk=4;38;2;249;38;114:*.ari=0;38;2;214;119;0:*.arj=4;38;2;249;38;114:*.arw=0;38;2;214;119;0:*.asa=0;38;2;0;174;63:*.asm=0;38;2;0;174;63:*.aux=0;38;2;122;112;112:*.avi=0;38;2;214;119;0:*.awk=0;38;2;0;174;63:*.bag=4;38;2;249;38;114:*.bak=0;38;2;122;112;112:*.bat=1;38;2;249;38;114:*.bay=0;38;2;214;119;0:*.bbl=0;38;2;122;112;112:*.bcf=0;38;2;122;112;112:*.bib=0;38;2;100;163;0:*.bin=4;38;2;249;38;114:*.blg=0;38;2;122;112;112:*.bmp=0;38;2;214;119;0:*.bsh=0;38;2;0;174;63:*.bst=0;38;2;100;163;0:*.bz2=4;38;2;249;38;114:*.c++=0;38;2;0;174;63:*.cap=0;38;2;214;119;0:*.cfg=0;38;2;100;163;0:*.cgi=0;38;2;0;174;63:*.clj=0;38;2;0;174;63:*.com=1;38;2;249;38;114:*.cpp=0;38;2;0;174;63:*.cr2=0;38;2;214;119;0:*.cr3=0;38;2;214;119;0:*.crw=0;38;2;214;119;0:*.css=0;38;2;0;174;63:*.csv=0;38;2;154;143;0:*.csx=0;38;2;0;174;63:*.cxx=0;38;2;0;174;63:*.dae=0;38;2;214;119;0:*.dcr=0;38;2;214;119;0:*.dcs=0;38;2;214;119;0:*.deb=4;38;2;249;38;114:*.def=0;38;2;0;174;63:*.dll=1;38;2;249;38;114:*.dmg=4;38;2;249;38;114:*.dng=0;38;2;214;119;0:*.doc=0;38;2;230;219;116:*.dot=0;38;2;0;174;63:*.dox=0;38;2;100;163;0:*.dpr=0;38;2;0;174;63:*.drf=0;38;2;214;119;0:*.dxf=0;38;2;214;119;0:*.eip=0;38;2;214;119;0:*.elc=0;38;2;0;174;63:*.elm=0;38;2;0;174;63:*.epp=0;38;2;0;174;63:*.eps=0;38;2;214;119;0:*.erf=0;38;2;214;119;0:*.erl=0;38;2;0;174;63:*.exe=1;38;2;249;38;114:*.exr=0;38;2;214;119;0:*.exs=0;38;2;0;174;63:*.fbx=0;38;2;214;119;0:*.fff=0;38;2;214;119;0:*.fls=0;38;2;122;112;112:*.flv=0;38;2;214;119;0:*.fnt=0;38;2;214;119;0:*.fon=0;38;2;214;119;0:*.fsi=0;38;2;0;174;63:*.fsx=0;38;2;0;174;63:*.gif=0;38;2;214;119;0:*.git=0;38;2;122;112;112:*.gpr=0;38;2;214;119;0:*.gvy=0;38;2;0;174;63:*.h++=0;38;2;0;174;63:*.hda=0;38;2;214;119;0:*.hip=0;38;2;214;119;0:*.hpp=0;38;2;0;174;63:*.htc=0;38;2;0;174;63:*.htm=0;38;2;154;143;0:*.hxx=0;38;2;0;174;63:*.ico=0;38;2;214;119;0:*.ics=0;38;2;230;219;116:*.idx=0;38;2;122;112;112:*.igs=0;38;2;214;119;0:*.iiq=0;38;2;214;119;0:*.ilg=0;38;2;122;112;112:*.img=4;38;2;249;38;114:*.inc=0;38;2;0;174;63:*.ind=0;38;2;122;112;112:*.ini=0;38;2;100;163;0:*.inl=0;38;2;0;174;63:*.ino=0;38;2;0;174;63:*.ipp=0;38;2;0;174;63:*.iso=4;38;2;249;38;114:*.jar=4;38;2;249;38;114:*.jpg=0;38;2;214;119;0:*.jsx=0;38;2;0;174;63:*.jxl=0;38;2;214;119;0:*.k25=0;38;2;214;119;0:*.kdc=0;38;2;214;119;0:*.kex=0;38;2;230;219;116:*.kra=0;38;2;214;119;0:*.kts=0;38;2;0;174;63:*.log=0;38;2;122;112;112:*.ltx=0;38;2;0;174;63:*.lua=0;38;2;0;174;63:*.m3u=0;38;2;214;119;0:*.m4a=0;38;2;214;119;0:*.m4v=0;38;2;214;119;0:*.mdc=0;38;2;214;119;0:*.mef=0;38;2;214;119;0:*.mid=0;38;2;214;119;0:*.mir=0;38;2;0;174;63:*.mkv=0;38;2;214;119;0:*.mli=0;38;2;0;174;63:*.mos=0;38;2;214;119;0:*.mov=0;38;2;214;119;0:*.mp3=0;38;2;214;119;0:*.mp4=0;38;2;214;119;0:*.mpg=0;38;2;214;119;0:*.mrw=0;38;2;214;119;0:*.msi=4;38;2;249;38;114:*.mtl=0;38;2;214;119;0:*.nef=0;38;2;214;119;0:*.nim=0;38;2;0;174;63:*.nix=0;38;2;100;163;0:*.nrw=0;38;2;214;119;0:*.obj=0;38;2;214;119;0:*.obm=0;38;2;214;119;0:*.odp=0;38;2;230;219;116:*.ods=0;38;2;230;219;116:*.odt=0;38;2;230;219;116:*.ogg=0;38;2;214;119;0:*.ogv=0;38;2;214;119;0:*.orf=0;38;2;214;119;0:*.org=0;38;2;154;143;0:*.otf=0;38;2;214;119;0:*.otl=0;38;2;214;119;0:*.out=0;38;2;122;112;112:*.pas=0;38;2;0;174;63:*.pbm=0;38;2;214;119;0:*.pcx=0;38;2;214;119;0:*.pdf=0;38;2;230;219;116:*.pef=0;38;2;214;119;0:*.pgm=0;38;2;214;119;0:*.php=0;38;2;0;174;63:*.pid=0;38;2;122;112;112:*.pkg=4;38;2;249;38;114:*.png=0;38;2;214;119;0:*.pod=0;38;2;0;174;63:*.ppm=0;38;2;214;119;0:*.pps=0;38;2;230;219;116:*.ppt=0;38;2;230;219;116:*.pro=0;38;2;100;163;0:*.ps1=0;38;2;0;174;63:*.psd=0;38;2;214;119;0:*.ptx=0;38;2;214;119;0:*.pxn=0;38;2;214;119;0:*.pyc=0;38;2;122;112;112:*.pyd=0;38;2;122;112;112:*.pyo=0;38;2;122;112;112:*.qoi=0;38;2;214;119;0:*.r3d=0;38;2;214;119;0:*.raf=0;38;2;214;119;0:*.rar=4;38;2;249;38;114:*.raw=0;38;2;214;119;0:*.rpm=4;38;2;249;38;114:*.rst=0;38;2;154;143;0:*.rtf=0;38;2;230;219;116:*.rw2=0;38;2;214;119;0:*.rwl=0;38;2;214;119;0:*.rwz=0;38;2;214;119;0:*.sbt=0;38;2;0;174;63:*.sql=0;38;2;0;174;63:*.sr2=0;38;2;214;119;0:*.srf=0;38;2;214;119;0:*.srw=0;38;2;214;119;0:*.stl=0;38;2;214;119;0:*.stp=0;38;2;214;119;0:*.sty=0;38;2;122;112;112:*.svg=0;38;2;214;119;0:*.swf=0;38;2;214;119;0:*.swp=0;38;2;122;112;112:*.sxi=0;38;2;230;219;116:*.sxw=0;38;2;230;219;116:*.tar=4;38;2;249;38;114:*.tbz=4;38;2;249;38;114:*.tcl=0;38;2;0;174;63:*.tex=0;38;2;0;174;63:*.tga=0;38;2;214;119;0:*.tgz=4;38;2;249;38;114:*.tif=0;38;2;214;119;0:*.tml=0;38;2;100;163;0:*.tmp=0;38;2;122;112;112:*.toc=0;38;2;122;112;112:*.tsx=0;38;2;0;174;63:*.ttf=0;38;2;214;119;0:*.txt=0;38;2;154;143;0:*.typ=0;38;2;154;143;0:*.usd=0;38;2;214;119;0:*.vcd=4;38;2;249;38;114:*.vim=0;38;2;0;174;63:*.vob=0;38;2;214;119;0:*.vsh=0;38;2;0;174;63:*.wav=0;38;2;214;119;0:*.wma=0;38;2;214;119;0:*.wmv=0;38;2;214;119;0:*.wrl=0;38;2;214;119;0:*.x3d=0;38;2;214;119;0:*.x3f=0;38;2;214;119;0:*.xlr=0;38;2;230;219;116:*.xls=0;38;2;230;219;116:*.xml=0;38;2;154;143;0:*.xmp=0;38;2;100;163;0:*.xpm=0;38;2;214;119;0:*.xvf=0;38;2;214;119;0:*.yml=0;38;2;100;163;0:*.zig=0;38;2;0;174;63:*.zip=4;38;2;249;38;114:*.zsh=0;38;2;0;174;63:*.zst=4;38;2;249;38;114:*TODO=1:*hgrc=0;38;2;100;163;0:*.avif=0;38;2;214;119;0:*.bash=0;38;2;0;174;63:*.braw=0;38;2;214;119;0:*.conf=0;38;2;100;163;0:*.dart=0;38;2;0;174;63:*.data=0;38;2;214;119;0:*.diff=0;38;2;0;174;63:*.docx=0;38;2;230;219;116:*.epub=0;38;2;230;219;116:*.fish=0;38;2;0;174;63:*.flac=0;38;2;214;119;0:*.h264=0;38;2;214;119;0:*.hack=0;38;2;0;174;63:*.heif=0;38;2;214;119;0:*.hgrc=0;38;2;100;163;0:*.html=0;38;2;154;143;0:*.iges=0;38;2;214;119;0:*.info=0;38;2;154;143;0:*.java=0;38;2;0;174;63:*.jpeg=0;38;2;214;119;0:*.json=0;38;2;100;163;0:*.less=0;38;2;0;174;63:*.lisp=0;38;2;0;174;63:*.lock=0;38;2;122;112;112:*.make=0;38;2;100;163;0:*.mojo=0;38;2;0;174;63:*.mpeg=0;38;2;214;119;0:*.nims=0;38;2;0;174;63:*.opus=0;38;2;214;119;0:*.orig=0;38;2;122;112;112:*.pptx=0;38;2;230;219;116:*.prql=0;38;2;0;174;63:*.psd1=0;38;2;0;174;63:*.psm1=0;38;2;0;174;63:*.purs=0;38;2;0;174;63:*.raku=0;38;2;0;174;63:*.rlib=0;38;2;122;112;112:*.sass=0;38;2;0;174;63:*.scad=0;38;2;0;174;63:*.scss=0;38;2;0;174;63:*.step=0;38;2;214;119;0:*.tbz2=4;38;2;249;38;114:*.tiff=0;38;2;214;119;0:*.toml=0;38;2;100;163;0:*.usda=0;38;2;214;119;0:*.usdc=0;38;2;214;119;0:*.usdz=0;38;2;214;119;0:*.webm=0;38;2;214;119;0:*.webp=0;38;2;214;119;0:*.woff=0;38;2;214;119;0:*.xbps=4;38;2;249;38;114:*.xlsx=0;38;2;230;219;116:*.yaml=0;38;2;100;163;0:*stdin=0;38;2;122;112;112:*v.mod=0;38;2;100;163;0:*.blend=0;38;2;214;119;0:*.cabal=0;38;2;0;174;63:*.cache=0;38;2;122;112;112:*.class=0;38;2;122;112;112:*.cmake=0;38;2;100;163;0:*.ctags=0;38;2;122;112;112:*.dylib=1;38;2;249;38;114:*.dyn_o=0;38;2;122;112;112:*.gcode=0;38;2;0;174;63:*.ipynb=0;38;2;0;174;63:*.mdown=0;38;2;154;143;0:*.patch=0;38;2;0;174;63:*.rmeta=0;38;2;122;112;112:*.scala=0;38;2;0;174;63:*.shtml=0;38;2;154;143;0:*.swift=0;38;2;0;174;63:*.toast=4;38;2;249;38;114:*.woff2=0;38;2;214;119;0:*.xhtml=0;38;2;154;143;0:*Icon\r=0;38;2;122;112;112:*LEGACY=0;38;2;0;0;0;48;2;230;219;116:*NOTICE=0;38;2;0;0;0;48;2;230;219;116:*README=0;38;2;0;0;0;48;2;230;219;116:*go.mod=0;38;2;100;163;0:*go.sum=0;38;2;122;112;112:*passwd=0;38;2;100;163;0:*shadow=0;38;2;100;163;0:*stderr=0;38;2;122;112;112:*stdout=0;38;2;122;112;112:*.bashrc=0;38;2;0;174;63:*.config=0;38;2;100;163;0:*.dyn_hi=0;38;2;122;112;112:*.flake8=0;38;2;100;163;0:*.gradle=0;38;2;0;174;63:*.groovy=0;38;2;0;174;63:*.ignore=0;38;2;100;163;0:*.matlab=0;38;2;0;174;63:*.nimble=0;38;2;0;174;63:*COPYING=0;38;2;182;182;182:*INSTALL=0;38;2;0;0;0;48;2;230;219;116:*LICENCE=0;38;2;182;182;182:*LICENSE=0;38;2;182;182;182:*TODO.md=1:*VERSION=0;38;2;0;0;0;48;2;230;219;116:*.alembic=0;38;2;214;119;0:*.desktop=0;38;2;100;163;0:*.gemspec=0;38;2;100;163;0:*.mailmap=0;38;2;100;163;0:*Doxyfile=0;38;2;100;163;0:*Makefile=0;38;2;100;163;0:*TODO.txt=1:*setup.py=0;38;2;100;163;0:*.DS_Store=0;38;2;122;112;112:*.cmake.in=0;38;2;100;163;0:*.fdignore=0;38;2;100;163;0:*.kdevelop=0;38;2;100;163;0:*.markdown=0;38;2;154;143;0:*.rgignore=0;38;2;100;163;0:*.tfignore=0;38;2;100;163;0:*CHANGELOG=0;38;2;0;0;0;48;2;230;219;116:*COPYRIGHT=0;38;2;182;182;182:*README.md=0;38;2;0;0;0;48;2;230;219;116:*bun.lockb=0;38;2;122;112;112:*configure=0;38;2;100;163;0:*.gitconfig=0;38;2;100;163;0:*.gitignore=0;38;2;100;163;0:*.localized=0;38;2;122;112;112:*.scons_opt=0;38;2;122;112;112:*.timestamp=0;38;2;122;112;112:*CODEOWNERS=0;38;2;100;163;0:*Dockerfile=0;38;2;100;163;0:*INSTALL.md=0;38;2;0;0;0;48;2;230;219;116:*README.txt=0;38;2;0;0;0;48;2;230;219;116:*SConscript=0;38;2;100;163;0:*SConstruct=0;38;2;100;163;0:*.cirrus.yml=0;38;2;230;219;116:*.gitmodules=0;38;2;100;163;0:*.synctex.gz=0;38;2;122;112;112:*.travis.yml=0;38;2;230;219;116:*INSTALL.txt=0;38;2;0;0;0;48;2;230;219;116:*LICENSE-MIT=0;38;2;182;182;182:*MANIFEST.in=0;38;2;100;163;0:*Makefile.am=0;38;2;100;163;0:*Makefile.in=0;38;2;122;112;112:*.applescript=0;38;2;0;174;63:*.fdb_latexmk=0;38;2;122;112;112:*.webmanifest=0;38;2;100;163;0:*CHANGELOG.md=0;38;2;0;0;0;48;2;230;219;116:*CONTRIBUTING=0;38;2;0;0;0;48;2;230;219;116:*CONTRIBUTORS=0;38;2;0;0;0;48;2;230;219;116:*appveyor.yml=0;38;2;230;219;116:*configure.ac=0;38;2;100;163;0:*.bash_profile=0;38;2;0;174;63:*.clang-format=0;38;2;100;163;0:*.editorconfig=0;38;2;100;163;0:*CHANGELOG.txt=0;38;2;0;0;0;48;2;230;219;116:*.gitattributes=0;38;2;100;163;0:*.gitlab-ci.yml=0;38;2;230;219;116:*CMakeCache.txt=0;38;2;122;112;112:*CMakeLists.txt=0;38;2;100;163;0:*LICENSE-APACHE=0;38;2;182;182;182:*pyproject.toml=0;38;2;100;163;0:*CODE_OF_CONDUCT=0;38;2;0;0;0;48;2;230;219;116:*CONTRIBUTING.md=0;38;2;0;0;0;48;2;230;219;116:*CONTRIBUTORS.md=0;38;2;0;0;0;48;2;230;219;116:*.sconsign.dblite=0;38;2;122;112;112:*CONTRIBUTING.txt=0;38;2;0;0;0;48;2;230;219;116:*CONTRIBUTORS.txt=0;38;2;0;0;0;48;2;230;219;116:*requirements.txt=0;38;2;100;163;0:*package-lock.json=0;38;2;122;112;112:*CODE_OF_CONDUCT.md=0;38;2;0;0;0;48;2;230;219;116:*.CFUserTextEncoding=0;38;2;122;112;112:*CODE_OF_CONDUCT.txt=0;38;2;0;0;0;48;2;230;219;116:*azure-pipelines.yml=0;38;2;230;219;116"
