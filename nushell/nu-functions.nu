# For now, we'll use the built-in completions feature as a convenient way for the user to select a repository, by typing
# characters to narrow down from the list. But I have a problem with fuzzy matching vs the default (prefix matching).
# You can change the *overall* completion setting for Nushell, which will help here, but that would be a regression for
# normal shell behavior. That's a bad tradeoff.
#
# I briefly looked and I don't think you change the completion setting for a specific command. I'm curious if Nushell
# exposes the tool/thing it uses for 'Ctrl+R' style history search, which does use fuzzy matching. Interesting.
#
# In the end, I'll probably reach for fzf. Not sure.
def repos [] {
    glob --no-file --depth 2 '~/repos/*/*'
}

# Change to one of my repositories. By convention, my repositories are in categorized subfolder in '~/repos'. For
# example:
#     * ~/repos/opensource/nushell
#     * ~/repos/personal/nushell-playground
#     * ~/repos/personal/my-config
export def --env cd-repo [repo : string@repos] {
    cd $repo
}
