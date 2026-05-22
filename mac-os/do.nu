# I need to source library code by path because this is a bootstrapping problem. On new installs, nothing will be
# installed into "$nu.default-config-dir/scripts" yet.
use ../nushell/scripts/zdu.nu err

const DIR = path self | path dirname
const NUTEST_REPO_URL = "https://github.com/vyadh/nutest.git"
const NUTEST_COMMIT = "d56fdc632b96754153a014c021d65a6633fc5610"

# Install my LLM rules files
#
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


# Install Nutest module from source.
#
# Call to action: periodically check the upstream and update `NUTEST_COMMIT` as needed.
#
# This command also patches a small problem in Nutest. Nutest dynamically constructs some Nu code with `use/source`
# commands and executes it, but it is not escaping the path. So for me, I was getting parse-time errors like the following:
#
#    use /Users/me/Library/Application Support/nushell/scripts/nutest/runner.nu *
#       ╰── module /Users/me/Library/Application not found
#
export def install-nutest [] {
    cd $DIR

    let source_parent_dir = "~/repos/opensource" | path expand
    let source_dir = [$source_parent_dir nutest] | path join
    let module_parent_dir = [$nu.default-config-dir scripts] | path join
    let module_dir = [$module_parent_dir nutest] | path join

    mkdir $source_parent_dir
    mkdir $module_parent_dir

    if ($source_dir | path exists) {
        ^git -C $source_dir fetch origin
    } else {
        ^git clone $NUTEST_REPO_URL $source_dir
    }

    ^git -C $source_dir checkout --detach $NUTEST_COMMIT

    let checked_out_commit = (^git -C $source_dir rev-parse HEAD | str trim)
    if ($checked_out_commit != $NUTEST_COMMIT) {
        err $"Expected Nutest commit ($NUTEST_COMMIT) but checked out ($checked_out_commit)."
    }

    patch-nutest-file (
        [$source_dir nutest orchestrator.nu] | path join
    ) "use ($runner_module) *" "use ($runner_module | to nuon) *"
    patch-nutest-file (
        [$source_dir nutest orchestrator.nu] | path join
    ) "source ($path)" "source ($path | to nuon)"
    patch-nutest-file (
        [$source_dir nutest discover.nu] | path join
    ) '$"source ($file); ($query)"' '$"source ($file | to nuon); ($query)"'

    if ($module_dir | path exists) {
        rm -r -f $module_dir
    }
    cp -r ([$source_dir nutest] | path join) $module_parent_dir

    print $"Nutest commit ($NUTEST_COMMIT) installed to ($module_dir)."
    print $"Pinned sources saved in ($source_dir)."
}

# Patch the given Nutest source code file by replacing the "old" string with the "new" one.
#
def patch-nutest-file [file: path, old: string, new: string] {
    let contents = open --raw $file

    if not ($contents | str contains $old) {
        err $"Expected to patch '($file)' but the target text was not found."
    }

    $contents
      | str replace $old $new
      | save --force --raw $file
}
