# Workflow

* Always read the @README.md to understand the vision of the project
* Always read the file `.my/REFERENCE.txt` (if it exists) before getting working. It contains curated reference material critical to your alignment.
* Always read the full file contents of files in 'src/' before working on code.


# Miscellaneous

* Pay special attention to the "Wish List" section of the README to anchor your work on the "IN PROGRESS" task if it exists.
* You DO NOT have access to Nushell, only Bash. Don't try to run the commands in `.nu` files. You should study the `do.nu` file as reference, however.
* Never try to delete files yourself, instead ask me to do it.
* Never delete existing comments. When re-writing code, always keep the original comments.
* Never add your own comments unless they are explaining some cryptic or unusual code.
* We are depending on the LLM to do smart things. We need to teach the LLM how to use the tools, by way of good instructions/tool-descriptions. Never write "bookmark matching heuristic" code that does stuff like keyword string matching. That's a smell that you're not using the LLM for what it's good at and instead relying on old school thinking.