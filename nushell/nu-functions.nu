# For now, we'll use the built-in completions feature as a convenient way for the user to select a repository, by typing
# characters to narrow down from the list. But I have a problem with fuzzy matching vs the default (start of string matching).
# You can change the *overall* completion setting for Nushell, which will help here, but that would be a regression for
# normal shell behavior. That's a bad tradeoff.
#
# I briefly looked and I don't think you change the completion setting for a specific command. I'm curious if Nushell
# exposes the tool/thing it uses for 'Ctrl+R' style history search, which does use fuzzy matching. Interesting.
#
# In the end, I'll probably reach for fzf. Not sure.
def personal-repos [] {
  ls --short-names ~/repos/personal | get name
}

# Change to one of my repositories in '~/repos/personal'.
export def --env cd-repo [repo : string@personal-repos] {
  [$nu.home-path repos/personal $repo] | path join | cd $in
}
