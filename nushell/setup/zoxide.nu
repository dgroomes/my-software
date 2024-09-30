# This is a zoxide-generated file, but I'm version controlling it and editing it for my own needs. As new versions of
# zoxide are released, consider re-initializing this file with `zoxide init nushell`, studying the diff, and making a
# decision about which existing customizations to keep and which new zoxide features to adopt.

use ../lib/lib.nu *

# =============================================================================
#
# Hook configuration for zoxide.
#

# Initialize hook to add new entries to the database.
if (not ($env | default false __zoxide_hooked | get __zoxide_hooked)) {
  $env.__zoxide_hooked = true
  $env.config = ($env | default {} config).config
  $env.config = ($env.config | default {} hooks)
  $env.config = ($env.config | update hooks ($env.config.hooks | default {} env_change))
  $env.config = ($env.config | update hooks.env_change ($env.config.hooks.env_change | default [] PWD))
  $env.config = ($env.config | update hooks.env_change.PWD ($env.config.hooks.env_change.PWD | append {|_, dir|
    zoxide add -- $dir
  }))
}

# =============================================================================
#
# My customizations for zoxide.
#
# zoxide is designed to be used with 'z' and 'zi' (interactive) commands. I'm inspired by this flow, but adapting the
# frontend experience to my own needs. Specifically, I'm only interested in interactive mode, so I can use the coveted
# single-character 'z' command to launch an interactive search. zoxide is designed to use 'fzf' but I'll use my own
# 'fz' search frontend, which is implemented with BubbleTea.
#
# I imagine there's value in having upfront options to the "interactive cd" experience, but honestly, I'm so used to
# basic 'cd' that I don't have the imagination for that yet. I'm only jumping to 'an interactive cd' experience based
# on the 'frecency' score (frequency + recency. See https://github.com/ajeetdsouza/zoxide/wiki/Algorithm#frecency) of
# the directories I've visited. zoxide is doing the heavy lifting on
# the backend to keep a database, update it on every directory change, and calculate the frecency score.
def --env z [] {
  let result = zoxide query --list --exclude (pwd) | complete
  if ($result.exit_code != 0) {
    error make { msg: $"zoxide query failed: ($result.stderr)" }
  }

  let dir = $result.stdout | lines | fz
  if ($dir | is-empty) { return }
  cd $dir
}
