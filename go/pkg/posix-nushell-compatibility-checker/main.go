package main

import (
	"bytes"
	"encoding/json"
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
		fmt.Fprintf(os.Stderr, "Error reading from standard input: %v\n", err)
		os.Exit(1)
	}
	snippet := string(inBytes)
	ok, err := CompatibleSnippet(snippet)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Something went wrong: %v\n", err)
		os.Exit(1)
	} else if ok {
		os.Exit(0)
	} else {
		os.Exit(1)
	}
}

func CompatibleSnippet(snippet string) (bool, error) {
	node, err := ParsePosixShell(snippet)
	if err != nil {
		return false, err
	}
	ast, err := ParseNu(snippet)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing input: %v\n", err)
		return false, err
	}

	printNode(node, 0)
	fmt.Println(ast)
	return CompatibleAsts(node, ast), nil
}

func CompatibleAsts(posixShellNode syntax.Node, nuAst map[string]interface{}) bool {
	return true
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

func ParsePosixShell(snippet string) (syntax.Node, error) {
	parser := syntax.NewParser()
	return parser.Parse(strings.NewReader(snippet), "")
}

// ParseNu calls the 'nushell-ast-printer' external command to get a JSON representation of the AST for the given Nushell snippet.
func ParseNu(snippet string) (map[string]interface{}, error) {
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
			return nil, fmt.Errorf("the 'nushell-ast-printer' command was not found")
		}
		if (err.(*exec.ExitError)).ExitCode() == 1 {
			return nil, fmt.Errorf("error running 'nushell-ast-printer': %v\n", err)
		}
	}

	var astMap map[string]interface{}
	if err := json.Unmarshal(stdout.Bytes(), &astMap); err != nil {
		return nil, fmt.Errorf("error unmarshalling JSON: %v\n", err)
	}

	return astMap, nil
}
