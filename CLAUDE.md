# Claude Instructions for 'my-software'

The 'my-software' repository is a monorepo. Claude working sessions occur in one subproject at a time. This is called
your FOCUSED SUBPROJECT. At the beginning of a new session you MUST read the `README.md` of the focused subproject.
You can infer the focused subproject based on the current working directory.

Example subprojects:

* `go/`
* `java/my-intellij-plugin/`
* `homebrew/`


## Goal Setting

When planning your architectural code changes, always keep in mind the guidance and vision of the subproject as outlined
in its `README.md`. If there exists a "Current Focus" section in the focused subproject's `CLAUDE.md`, you must anchor
yourself on that as well and proactively start working towards it.


## Universal Routines

Common things I'll ask you to do which applies to any subproject (e.g. universal).

1. *Study attachments* - List the files in the `attachments/` directory of the focused subproject and study them
   carefully. 
