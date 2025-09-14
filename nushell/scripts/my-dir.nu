use zdu.nu *

# Initialize a new ".my" directory based on my conventions.
#
# I use the '.my' directory to build up specific workflows and context for my own development work. This command
# creates  these conventional files:
#   - .my/do.nu
#   - .my/AGENT.md
#   - .my/PROMPT.md (this is used for bundling up context for a one-shot LLM prompt; not for agents)
#
# You are expected to write as much miscellaneous code in the 'do.nu' as you need. The initialized versions of these
# files are a minimal starting point geared at bundling up the context for pasting into an LLM chat.
#
export def my-dir-init [] {
    mkdir .my
    cd .my

    my-agent-file
    my-prompt-file
    my-do-file
}

def my-agent-file [] {
    r#'
# Instructions

These instructions are for you, an LLM-powered agentic collaborator.

- Start by reading the README.md file in the project's root directory for context.
- Look for an IN PROGRESS task, if present. This is your focus.
- Use the below instructions for further guidance on the current task.

# Current task: n/a
'# | save AGENT.md
}

def my-prompt-file [] {
   # It shouldn't be necessary, but I needed to add an extra # in the raw string delimiter because the leading # for
   # a normal raw string (#') was causing a syntax issue. That should have worked because the leading # was not followed
   # by a quote, but I imagine it's an edge case? Or I'm misinterpreting something.
   r##'# Instructions

(write your instructions for the LLM here)
'## | save PROMPT.md
}

def my-do-file [] {
    r#'const DIR = path self | path dirname

# Bundle up the prompt file and all the context described by the "file sets" into a string ready to be pasted into an
# LLM chat app.
export def bundle [] {
    cd $DIR
    let prompt = open --raw PROMPT.md
    let fs_bundles = glob *.file-set.json | each { bundle file-set $in }
    let bun = [$prompt ...$fs_bundles "The original request as a refresher:" $prompt] | str join $"\n\n"

    $bun | save --force bundle.txt
    $bun | pbcopy
    let token_count = $bun | token-count | into int | comma-per-thousand
    print $"Bundle created: ($token_count) tokens and copied to clipboard."
}

export def example-fs [] {
    cd $DIR
    let root = "~/repos/opensource/example"
    let fs_name = "example.file-set.json"

    let fs = do {
        cd $root
        let files = fd --type file | where (is-text-file)
        { root: $root files: $files }
    }

    $fs | save --force $fs_name
    $fs | file-set summarize | table --index false --expand --theme light
}

'# | save do.nu
}
