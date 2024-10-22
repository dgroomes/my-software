package main

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"

	"mvdan.cc/sh/v3/syntax"
)

func main() {
	inBytes, err := io.ReadAll(os.Stdin)
	if err != nil {
		fatal(fmt.Sprintf("Error reading from standard input: %v\n", err))
	}
	expression := string(inBytes)
	parser := syntax.NewParser()
	file, err := parser.Parse(strings.NewReader(expression), "")
	if err != nil {
		fatal(fmt.Sprintf("Error parsing input: %v\n", err))
	}

	printNode(file, 0)

	fmt.Println(nushellAst(expression))
}

func printNode(node syntax.Node, indent int) {
	nodeType := fmt.Sprintf("%T", node)
	var nodeValue string

	switch x := node.(type) {
	case *syntax.Lit:
		nodeValue = fmt.Sprintf(" (%q)", x.Value)
	case *syntax.Word:
		nodeValue = fmt.Sprintf(" (%q)", x.Lit())
	case *syntax.ParamExp:
		nodeValue = fmt.Sprintf(" ($%s)", x.Param.Value)
	}

	fmt.Printf("%s%s%s\n", indentation(indent), nodeType, nodeValue)

	switch x := node.(type) {
	case *syntax.File:
		for _, stmt := range x.Stmts {
			printNode(stmt, indent+1)
		}
	case *syntax.Stmt:
		if x.Cmd != nil {
			printNode(x.Cmd, indent+1)
		}
		for _, redirect := range x.Redirs {
			printNode(redirect, indent+1)
		}
	case *syntax.CallExpr:
		for _, assign := range x.Assigns {
			printNode(assign, indent+1)
		}
		for _, word := range x.Args {
			printNode(word, indent+1)
		}
	case *syntax.Word:
		for _, part := range x.Parts {
			printNode(part, indent+1)
		}
	case *syntax.Assign:
		printNode(x.Name, indent+1)
		if x.Value != nil {
			printNode(x.Value, indent+1)
		}
	case *syntax.ParamExp:
		printNode(x.Param, indent+1)
	case *syntax.CmdSubst:
		for _, stmt := range x.Stmts {
			printNode(stmt, indent+1)
		}
	case *syntax.DblQuoted:
		for _, part := range x.Parts {
			printNode(part, indent+1)
		}
	}
}

func indentation(level int) string {
	return strings.Repeat("  ", level)
}

// Call the 'nushell-ast-printer' external command to get a JSON representation of the AST for the given Nushell snippet.
func nushellAst(snippet string) string {
	cmd := exec.Command("nushell-ast-printer")
	cmd.Stdin = bytes.NewBufferString(snippet)

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		if stderr.Len() > 0 {
			fmt.Fprintln(os.Stderr, stderr.String())
		}

		var execErr *exec.Error
		if errors.As(err, &execErr) && errors.Is(execErr.Err, exec.ErrNotFound) {
			fatal(fmt.Sprintf("The 'nushell-ast-printer' command was not found"))
		}
		if (err.(*exec.ExitError)).ExitCode() == 1 {
			fatal(fmt.Sprintf("Error running 'nushell-ast-printer': %v", err))
		}
	}

	return stdout.String()
}

//go:noreturn
func fatal(msg string) {
	//goland:noinspection GoUnhandledErrorResult
	fmt.Fprintln(os.Stderr, msg)
	os.Exit(1)
}
