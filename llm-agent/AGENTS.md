# My Global Agent Instructions

## The .my directory

- Know the `.my/` directory. This is a directory-local convention where I use a `.my/` directory to store personal scripting, notes, scratch files.
- It is globally .gitignore-d. I often have a `.my/` in my local Git clones. You are ALLOWED and EXPECTED to read the files in `.my/` directories to better understand my own context and pattersn of a project 
- Get leverage from `.my/do.nu`. I often have a `.my/do.nu` file which is a convenience script for running project tasks. I will overlay that file into my Nushell session so that I can issue `make`-like commands defined for my project: `do build`, `do xyz`, etc. But, your shell is NOT Nushell, it's Bash. So, if you want to run one of these commands do it like this: `nu -c "overlay use --prefix .my/do.nu; do xyz"`


## Wish Lists

- In projects that I manage, I'll use a 'Wish List' TODO-like section.
- An IN PROGRESS task is a strong indicator of my current focus. Anchor to that in the absence of other instruction
- Never edit Wish List items. I will be the one to turn an IN PROGRESS task to DONE, etc.


## General

- Rarely delete existing comments. When re-writing code, always keep the original comments (especially when it has a human voice)
- Rarely add your own comments unless they are explaining some especially cryptic or unusual code.
