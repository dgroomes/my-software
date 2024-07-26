// UPDATE: This program does not serve me. I totally didn't understand that I could just do 'git status --porcelain' and
// get the same result. I'm going to commit this code for posterity and then delete it.
//
// This program supports the equivalent of 'git status' and prints the result as JSON.
//
// I made this program to help me script Git-related things in Nushell. The desire to have 'git' produce JSON is not
// new, see https://stackoverflow.com/a/51228920. The program is called 'git-json' and you can invoke it with
// 'git-json status' just like you would with 'git status'. Here are some examples:
//
//	In Directory:	~/repos/personal/my-config
//	Command:		git-json status
//	Exit Code:		0
//	stdout:			[ "go/README.md", "go/go.mod", "go/go.sum" ]
//
//	In Directory:	~/repos/opensource/nushell
//	Command:		git-json status
//	Exit Code:		0
//	stdout:			[]
//
//	In Directory:	~
//	Command:		git-json status
//	Exit Code:		1
//	stderr:			'/Users/dave' is not a Git repository (or any of its parent directories).
//
//	In Directory:	/some/dir/that/does/not/exist
//	Command:    	git-json status
//	Exit Code:  	1
//	stderr:     	'/some/dir/that/does/not/exist' is not a directory.
package main

import (
	"fmt"
	"github.com/go-git/go-git/v5"
	"os"
)
import "encoding/json"

func main() {
	if len(os.Args) < 2 || os.Args[1] != "status" {
		fmt.Fprintf(os.Stderr, "Usage: %s status\n", os.Args[0])
		os.Exit(1)
	}

	dir, err := os.Getwd()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error getting current directory: %v\n", err)
		os.Exit(1)
	}

	repo, err := git.PlainOpenWithOptions(dir, &git.PlainOpenOptions{
		DetectDotGit: true,
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error opening repository: %v\n", err)
		os.Exit(1)
	}

	wt, err := repo.Worktree()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error getting worktree: %v\n", err)
		os.Exit(1)
	}

	status, err := wt.Status()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error getting status: %v\n", err)
		os.Exit(1)
	}

	// Get only the file names and collect into a list. (I'm looking forward to the Go 1.23 way of doing this.)
	var fileNames []string
	for name, _ := range status {
		fileNames = append(fileNames, name)
	}

	// Turn status into JSON
	jsonStatus, err := json.MarshalIndent(fileNames, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error marshaling JSON: %v\n", err)
		os.Exit(1)
	}

	fmt.Println(string(jsonStatus))
}
