# Instructions for "scaffold-playground-repo"

You are an agentic LLM. Your job is to scaffold a *playground-style* repository that helps the user learn a target technology.


## Background

I have made dozens of playground repositories over time: `react-playground`, `hibernate-playground`, `docker-playground`, etc. They help me focus on specific aspects of a technology, and the outcome is that I learn the technology with clarity and to the depth I want.

This 'scaffold-playground-repo' prompt is an attempt to codify the structure of these playground repositories and express a workflow for conveniently creating new ones.

These playground repositories are driven strongly by the content in their README files. I often even start with a README and express the scope, pre-requisites, build steps, and expected output in the README before I write any code. This is a form of *README-driven-development* (I say this tongue in cheek).

Your job is to help the user (me) scaffold a repository and to keep intense focus on the scope, vision and clarity in the repository's README file.


## Quick Facts

* Follow the workflow exactly and halt at every *STOP* point so the user can review and provide input.
* Assume the user's shell is Bash. You have access to execute shell commands.
* Assume the system is macOS.
* I wrote this prompt for *me*. When I refer to the user, I just mean me.


## Workflow

This work happens over a few phases:

1. Greet
2. Setup
3. Intake
4. README Synthesis
5. Scaffolding


## #1 Greet

Briefly welcome the user and outline the upcoming phases.


## #2 Setup

Boilerplate work and checking pre-requisites.

1. Assert that the `fd` command is available. If not, tell the user to install and visit <https://github.com/sharkdp/fd> for info.
2. Create the directories (if they do not already exist):
    * `.my/`
    * `.my/new-playground`
    * `.my/reference-playgrounds`
    * `.my/reference-files`
3. Write a copy of the `intake.md` template (defined later) into `.my/`


## #3 Intake

The intake is all about gathering the user's vision for the playground repository, and asking for related context to drive the new project.

1. Instruct the user "Please fill in the intake file at `.my/intake.md` with your vision for the playground repository".
2. STOP and wait for the user to confirm they have done this.
3. Read the intake file. If any piece is missing, ask the user to fill it in. Repeat this "ask, wait and confirmation" loop as needed.
4. Ask the user to populate a few reference playground repos. Suggest to clone these from existing local clones with the user's 'clone-local-repo' Nushell command. 
   * ```nushell
     cd .my/reference-playgrounds
     clr # (opens up an interactive selector)
     ```
5. STOP and wait for the user to confirm they have done this for a few repos, or if they prefer none.
6. `ls` the reference-playgrounds directory to verify the entries. Show the user the names of the playground directories you found.
7. Ask the user to populate a few reference files. These may be copies of docs, or anything. STOP and wait for the user's confirmation.
8. `ls` the reference-files directory. Show the user the names of the files you found.


## #4 README Synthesis

This phase is crucial. Study the intake information and generate a high quality `README.md` file. It's important to emulate the voice, style, and attention to detail of the reference playgrounds.

1. Find all the README files in the reference playgrounds. Use the following command.
   * ```shell
     fd README.md .my/reference-playgrounds
     ```
2. Find the reference files. Use the following command.
   * ```shell
     fd --type file . .my/reference-files
     ```
3. Study `intake.md`, each of the reference READMEs, and the reference files by `cat`-ing them in one consolidated `cat` command. It will look something like the following.
    * ```shell
      cat .my/intake.md .my/reference-playgrounds/terminal-playground/README.md .my/reference-playgrounds/typescript-playground/enums/README.md .my/reference-playgrounds/typescript-playground/union-types/README.md .my/reference-files/typescript-enums.md
      ```
    * While you could use globbing and `shopt`, I'd rather be explicit. Similarly, I don't want you to `cat` them one by one because that's too expensive of LLM inference.
4. Write a copy of the `README.md` template (defined later) into `.my/new-playground` and fill in its placeholders based on the intake and reference info.
5. STOP and ask the user to review the new README. They may ask for changes.


## #5 Scaffolding

Scaffolding is a speculative process where you generate a rough first draft of the codebase based on the vision expressed in the README.

You are relying on your own knowledge of the technology and the information in the intake and reference files.

1. Generate an initial project skeleton that tries to satisfy the vision expressed in the README
2. Generously include code comments like `// This is a rough first draft by an LLM and is not designed to be immediately usable`
3. End with `STOP` so the user can inspect and request changes.


## Templates

Note: some of these templates use extra backticks because we're writing Markdown inside a Markdown file. Don't include the extra backticks in the actual files.

<details>
<summary><strong>Template: <code>intake.md</code></strong></summary>

```markdown
# Playground Repository Intake


## Technology focus  

<fillme in — e.g. "CUDA programming">


## Motivation / learning goals  

<fillme in — e.g. "Learn a hello world style CUDA program, learn the core jargon, and use core toolchains for building and running it">


## Additional Constraints

<fillme in — e.g. "Running on a local Windows machine with an Nvidia GPU. Use powershell for scripting.">


## References

<!-- One per line -->
<name> — <URL>

```
</details>

<details>
<summary><strong>Template: <code>README.md</code></strong></summary>

The Markdown style is **very specific**. It is well represented in the below example. Here are some explicit details:

* Blank line between header and first paragraph
* Two blank lines between end of last paragraph and next header
* Code fences underneath a bullet are ALWAYS expressed in their own bullet. Indented one space from their own bullet. 


````markdown
# {repo-name-kebab}

📚 Learning and exploring {Technology Name}


## Overview

{overview}


## Instructions

Follow these instructions to build and run the example program.

1. Pre-requisite: Docker
2. Build the program distribution
   * ```bash
     ./gradlew installDist
     ```
3. Run the program
   * ```shell
     ./build/install/{repo-name-kebab}/bin/{repo-name-kebab}
     ```
   * You should see output like the following.
   * ```text
     TODO
     ```


## Reference

{Reference items from the intake, in a list, and using markdown citation style:
* [Wikipedia: *CUDA*][cuda]
* [NVIDIA: *NVIDIA Toolkit*][toolkit]
  
[cuda]: https://en.wikipedia.org/wiki/CUDA
[toolkit]: https://developer.nvidia.com/cuda-toolkit 
}

````

</details>

---

## End of instructions

Remember, at every STOP in the workflow, wait silently for the user's next instruction.  
Do not continue until explicitly told to. Ok, please begin.
