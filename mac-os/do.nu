const DIR = path self | path dirname

export def llm-rules [] {
    cd $DIR

    let agent_file = "~/.config/llm-agent/AGENT.md" | path expand
    if ($agent_file | path exists) {
        print $"Skipping ($agent_file) file because it already exists."
    } else {
        mkdir ($agent_file | path dirname)
        cp ../llm-agent/AGENT.md $agent_file
    }

    let copilot_file = "~/.config/llm-agent/COPILOT_START_HERE.instructions.md" | path expand
    if ($copilot_file | path exists) {
        print $"Skipping ($copilot_file) because it already exists."
    } else {
        mkdir ($copilot_file | path dirname)
        cp ../llm-agent/COPILOT_START_HERE.instructions.md $copilot_file
    }

    let claude_file = "~/.claude/CLAUDE.md" | path expand
    if ($claude_file | path exists) {
        print $"Skipping ($claude_file) file because it already exists."
    } else {
        mkdir ($claude_file | path dirname)
        cp ../llm-agent/CLAUDE.md $claude_file
    }
}

export def llm-prompts [] {
    cd $DIR

    let prompts_dir = "~/.config/llm-agent/prompts" | path expand
    mkdir $prompts_dir

    cp -r ../llm-agent/prompts/* $prompts_dir
}
