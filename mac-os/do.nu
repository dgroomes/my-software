const DIR = path self | path dirname

export def llm-rules [] {
    cd $DIR

    if ("~/.config/llm-agent/AGENT.md" | path exists) {
        print $"Skipping AGENT.md file because it already exists."
    } else {
        mkdir ~/.config/llm-agent
        cp ../llm-agent/AGENT.md ~/.config/llm-agent
    }

    # Claude usually calls the "load_rules" tool of my Rules MCP server, but not always. I want auto-loading behavior to
    # always work.
    #
    # So, let's re-express the "START HERE" prompt in the vendor-specific rules files of the many agent tools out there.
    #
    # This stinks a bit because we're cluttering the home directory with these files and paying the cost of maintenance,
    # but this will have to do. One day there will likely be standardization.

    const rfs = [
        "~/.claude/CLAUDE.md"

        # I assumed that GitHub Copilot would have a global place to set instructions, but there isn't really. VS Code's
        # GitHub Copilot has a few activity-specific settings for setting global instructions (e.g. codegen, test
        # codegen, code review... ). See https://code.visualstudio.com/docs/copilot/copilot-customization
        #
        # That's not effective enough to get auto-loading in my copilot chats. That's fine. I just have to manually say
        # "!rules load" in each chat. Perfectly fine.
        #
        # This is NOT a convention location, I just assumed it was. Keeping for posterity.
        # "~/.github/copilot-instructions.md"

    ] | path expand

    for rf in $rfs {
        if ($rf | path exists) {
            print $"Skipping ($rf) because it already exists."
        } else {
            mkdir ($rf | path dirname)
            "START_HERE. ALWAYS use the 'rules:load_rules' tool to load your instructions. You MUST call this tool before starting any other work.\n" | save $rf
        }
    }
}
