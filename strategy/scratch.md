# scratch

Scratch pad of miscellaneous and uncategorized notes.


## Agent Client Protocol

ACP works and is pretty smooth in Intellij! Surprised to see such a long list of ACP integrations. Codex is working nicely for me. I like the GUI rendering instead of being stuck with monospaced TUI output (although a great TUI is truly great). And I really like the IDE autocomplete for file names as I prompting.

I still am a little confused about the value proposition because like where should tool configuration (allow listing and such) exist? On the lefhand side of the ACP (in the Intellij) or on the righthand side (in Codex-specific config?).

<https://agentclientprotocol.com/get-started/introduction>

And GitHub Copilot has implemented the ACP protocol??? <https://docs.github.com/en/copilot/reference/acp-server> This can obsolete the GitHub Intellij plugin (except for line completion, but for the agent, yeah for sure). This is an interesting inversion. 

Interesting, clicking a file link (like `vm.nu`) completely did not work. It somehow launched my browser.

Oh good, window resizing is also a great feature of the agent being in a GUI. The text properly reflows.


## Version Control Even When Not Sharing

Usually we version control in a sharing context, where we push to a shared Git *remote*, or a wiki with versioned pages/edits, etc. I'm finding that my local-only context in my `.my/` directory, where I put my prompts, is suffering from not having git. I'm choosing to just manually copy/rename the prompt file and put it into an 'archive/' location.

What I'd like is to use git (which I'm already doing with my `new-subject` *subject* dirs; but not to great effect). The other use case I'm thinking of is context compaction. I just mean this in a low tech where where I ask the agent to summarize the whole chat, and in the case it cuts out way too much stuff, I can revert to the original context, and the killer feature, if possible, is I can just view the diff of the compaction. I'm waving my hands on the implementation. But in principle this is the way. I drive so much of my best work by just judiciously reviewing my diffs.
