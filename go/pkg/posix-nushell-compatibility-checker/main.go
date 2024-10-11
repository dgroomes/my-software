package main

import (
	"fmt"
	"os"
	"strings"

	"mvdan.cc/sh/v3/syntax"
)

func main() {
	parser := syntax.NewParser()

	file, err := parser.Parse(os.Stdin, "")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing input: %v\n", err)
		os.Exit(1)
	}

	printNode(file, 0)
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
