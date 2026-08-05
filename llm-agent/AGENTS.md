# My Global Agent Instructions

- Pay special attention to the "Wish List" section of the README to anchor your work on the "IN PROGRESS" task if it exists (in the absence of other instruction)
- Know the `.my/` directory. This is a directory-local convention where I use a `.my/` directory to store personal scripting, notes, scratch files. It is globally .gitignore-d. I often have a `.my/` in my local Git clones. You are ALLOWED and EXPECTED to read the files in `.my/` directories to better understand my own context and pattersn of a project 
- Get leverage from `.my/do.nu`. I often have a `.my/do.nu` file which is a convenience script for running project tasks. I will overlay that file into my Nushell session so that I can issue `make`-like commands defined for my project: `do build`, `do xyz`, etc. But, your shell is NOT Nushell, it's Bash. So, if you want to run one of these commands do it like this: `nu -c "overlay use --prefix .my/do.nu; do xyz"`
- Rarely delete existing comments. When re-writing code, always keep the original comments (especially when it has a human voice)
- Rarely add your own comments unless they are explaining some especially cryptic or unusual code.
