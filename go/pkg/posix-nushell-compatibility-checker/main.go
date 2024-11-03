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
	snippet = strings.TrimSpace(snippet)
	fmt.Fprintf(os.Stderr, "Input snippet: %q\n", snippet)

	ok, err := CompatibleSnippet(snippet)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Something went wrong: %v\n", err)
		os.Exit(1)
	} else if ok {
		fmt.Fprintf(os.Stderr, "Command is compatible! ✅\n")
		os.Exit(0)
	} else {
		fmt.Fprintf(os.Stderr, "Command is not compatible! ❌\n")
		os.Exit(1)
	}
}

func CompatibleSnippet(snippet string) (bool, error) {
	fmt.Fprintf(os.Stderr, "\n=== Parsing POSIX Shell ===\n")
	posixNode, err := ParsePosixShell(snippet)
	if err != nil {
		return false, fmt.Errorf("POSIX parse error: %v", err)
	}
	printNode(posixNode, 0)

	fmt.Fprintf(os.Stderr, "\n=== Parsing Nushell ===\n")
	nuAst, err := ParseNu(snippet)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error parsing input: %v\n", err)
		return false, err
	}
	prettyJson, _ := json.MarshalIndent(nuAst, "", "  ")
	fmt.Fprintf(os.Stderr, "Nushell AST:\n%s\n", prettyJson)

	return CompatibleAsts(posixNode, nuAst), nil
}

func CompatibleAsts(posixShellNode syntax.Node, nuAst map[string]interface{}) bool {
	fmt.Fprintf(os.Stderr, "\n=== Checking Compatibility ===\n")

	fmt.Fprintf(os.Stderr, "1. Checking if POSIX command is simple...\n")
	isSimpleShellCmd := isSimplePosixCommand(posixShellNode)
	fmt.Fprintf(os.Stderr, "   POSIX simple command check: %v\n", isSimpleShellCmd)
	if !isSimpleShellCmd {
		return false
	}

	fmt.Fprintf(os.Stderr, "2. Checking if Nushell command is simple...\n")
	isSimpleNuCmd := isSimpleNushellCommand(nuAst)
	fmt.Fprintf(os.Stderr, "   Nushell simple command check: %v\n", isSimpleNuCmd)
	if !isSimpleNuCmd {
		return false
	}

	fmt.Fprintf(os.Stderr, "3. Comparing command structures...\n")
	match := compareCommandStructures(posixShellNode, nuAst)
	fmt.Fprintf(os.Stderr, "   Command structures match: %v\n", match)
	return match
}

func isSimplePosixCommand(node syntax.Node) bool {
	switch x := node.(type) {
	case *syntax.File:
		fmt.Fprintf(os.Stderr, "   POSIX File node with %d statements\n", len(x.Stmts))
		if len(x.Stmts) != 1 {
			fmt.Fprintf(os.Stderr, "   ❌ More than one statement\n")
			return false
		}
		return isSimplePosixCommand(x.Stmts[0])
	case *syntax.Stmt:
		fmt.Fprintf(os.Stderr, "   POSIX Stmt node\n")
		if len(x.Redirs) > 0 {
			fmt.Fprintf(os.Stderr, "   ❌ Has redirections\n")
			return false
		}
		if x.Background {
			fmt.Fprintf(os.Stderr, "   ❌ Has background operator\n")
			return false
		}
		if x.Coprocess {
			fmt.Fprintf(os.Stderr, "   ❌ Is a coprocess\n")
			return false
		}
		if x.Cmd == nil {
			fmt.Fprintf(os.Stderr, "   ❌ No command\n")
			return false
		}
		return isSimplePosixCommand(x.Cmd)
	case *syntax.CallExpr:
		fmt.Fprintf(os.Stderr, "   POSIX CallExpr with %d arguments\n", len(x.Args))
		if len(x.Assigns) > 0 {
			fmt.Fprintf(os.Stderr, "   ❌ Has assignments\n")
			return false
		}
		for i, arg := range x.Args {
			argLit := wordToString(arg)
			fmt.Fprintf(os.Stderr, "   Checking argument %d: %q\n", i, argLit)
			if !isSimpleWord(arg) {
				fmt.Fprintf(os.Stderr, "   ❌ Argument %d is not a simple word\n", i)
				return false
			}
		}
		fmt.Fprintf(os.Stderr, "   ✅ All arguments are simple\n")
		return true
	default:
		fmt.Fprintf(os.Stderr, "   ❌ Unexpected node type: %T\n", x)
		return false
	}
}

func isSimpleWord(word *syntax.Word) bool {
	fmt.Fprintf(os.Stderr, "   Examining word with %d parts\n", len(word.Parts))
	if len(word.Parts) != 1 {
		fmt.Fprintf(os.Stderr, "   ❌ Word has multiple parts\n")
		return false
	}
	switch part := word.Parts[0].(type) {
	case *syntax.Lit:
		fmt.Fprintf(os.Stderr, "   ✅ Simple literal: %q\n", part.Value)
		return true
	case *syntax.SglQuoted:
		fmt.Fprintf(os.Stderr, "   ✅ Simple single-quoted literal: %q\n", part.Value)
		return true
	case *syntax.DblQuoted:
		fmt.Fprintf(os.Stderr, "   Examining double-quoted word\n")
		for _, dqPart := range part.Parts {
			switch dqInner := dqPart.(type) {
			case *syntax.Lit:
				// Accept simple literals inside double quotes
			default:
				fmt.Fprintf(os.Stderr, "   ❌ DblQuoted part is not a simple literal: %T\n", dqInner)
				return false
			}
		}
		fmt.Fprintf(os.Stderr, "   ✅ Simple double-quoted literal\n")
		return true
	default:
		fmt.Fprintf(os.Stderr, "   ❌ Part is not a simple literal\n")
		return false
	}
}

func isSimpleNushellCommand(ast map[string]interface{}) bool {
	fmt.Fprintf(os.Stderr, "   Checking Nushell AST structure...\n")

	if ast["type"] != "Block" {
		fmt.Fprintf(os.Stderr, "   ❌ Root is not a Block\n")
		return false
	}

	children, ok := ast["children"].([]interface{})
	if !ok || len(children) != 1 {
		fmt.Fprintf(os.Stderr, "   ❌ Block doesn't have exactly one child\n")
		return false
	}

	call, ok := children[0].(map[string]interface{})
	if !ok || call["type"] != "Call" {
		fmt.Fprintf(os.Stderr, "   ❌ Child is not a Call\n")
		return false
	}

	fmt.Fprintf(os.Stderr, "   ✅ Nushell command is simple\n")
	return true
}

func compareCommandStructures(posixNode syntax.Node, nuAst map[string]interface{}) bool {
	fmt.Fprintf(os.Stderr, "=== Comparing Command Structures ===\n")

	// Extract POSIX command components
	posixCmdName, posixArgs, err := extractPosixCommandComponents(posixNode)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to extract POSIX command components: %v\n", err)
		return false
	}

	// Extract Nushell command components
	nuCmdName, nuArgs, err := extractNuCommandComponents(nuAst)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to extract Nushell command components: %v\n", err)
		return false
	}

	// Compare command names
	if posixCmdName != nuCmdName {
		fmt.Fprintf(os.Stderr, "❌ Command names do not match: %q vs %q\n", posixCmdName, nuCmdName)
		return false
	}

	// Compare argument counts
	if len(posixArgs) != len(nuArgs) {
		fmt.Fprintf(os.Stderr, "❌ Argument counts do not match: %d vs %d\n", len(posixArgs), len(nuArgs))
		return false
	}

	// Compare each argument
	for i := 0; i < len(posixArgs); i++ {
		if !compareArguments(posixArgs[i], nuArgs[i]) {
			fmt.Fprintf(os.Stderr, "❌ Arguments at position %d do not match\n", i)
			return false
		}
	}

	fmt.Fprintf(os.Stderr, "✅ Command structures match completely\n")
	return true
}

func extractPosixCommandComponents(node syntax.Node) (string, []*syntax.Word, error) {
	switch x := node.(type) {
	case *syntax.File:
		if len(x.Stmts) != 1 {
			return "", nil, fmt.Errorf("expected 1 statement, got %d", len(x.Stmts))
		}
		return extractPosixCommandComponents(x.Stmts[0])
	case *syntax.Stmt:
		if x.Cmd == nil {
			return "", nil, fmt.Errorf("statement has no command")
		}
		return extractPosixCommandComponents(x.Cmd)
	case *syntax.CallExpr:
		if len(x.Args) == 0 {
			return "", nil, fmt.Errorf("call expression has no arguments")
		}
		cmdName := wordToString(x.Args[0])
		args := x.Args[1:]
		return cmdName, args, nil
	default:
		return "", nil, fmt.Errorf("unexpected node type: %T", x)
	}
}

func extractNuCommandComponents(ast map[string]interface{}) (string, []interface{}, error) {
	children, ok := ast["children"].([]interface{})
	if !ok || len(children) == 0 {
		return "", nil, fmt.Errorf("no children in block")
	}

	call, ok := children[0].(map[string]interface{})
	if !ok || call["type"] != "Call" {
		return "", nil, fmt.Errorf("first child is not a Call")
	}

	callChildren, ok := call["children"].([]interface{})
	if !ok || len(callChildren) == 0 {
		return "", nil, fmt.Errorf("no children in Call")
	}

	cmdNode, ok := callChildren[0].(map[string]interface{})
	if !ok {
		return "", nil, fmt.Errorf("invalid command node")
	}

	cmdType, ok := cmdNode["type"].(string)
	if !ok {
		return "", nil, fmt.Errorf("command node has no type")
	}

	if cmdType != "Name" {
		return "", nil, fmt.Errorf("command node is not a Name type")
	}

	cmdName, ok := cmdNode["value"].(string)
	if !ok {
		return "", nil, fmt.Errorf("command node has no value")
	}

	args := callChildren[1:]

	return cmdName, args, nil
}

func compareArguments(posixArg *syntax.Word, nuArg interface{}) bool {
	nuArgMap, ok := nuArg.(map[string]interface{})
	if !ok {
		fmt.Fprintf(os.Stderr, "   ❌ Nushell argument is not a valid node\n")
		return false
	}

	nuArgType, ok := nuArgMap["type"].(string)
	if !ok {
		fmt.Fprintf(os.Stderr, "   ❌ Nushell argument has no type\n")
		return false
	}

	nuArgValue, ok := nuArgMap["value"].(string)
	if !ok {
		fmt.Fprintf(os.Stderr, "   ❌ Nushell argument has no value\n")
		return false
	}

	// Compare types
	posixArgType := getPosixArgType(posixArg)
	if !posixArgTypeMatchesNuArgType(posixArgType, nuArgType) {
		fmt.Fprintf(os.Stderr, "   ❌ Argument types do not match: POSIX %s vs Nushell %s\n", posixArgType, nuArgType)
		return false
	}

	// Compare values
	posixArgValue := wordToString(posixArg)
	if posixArgValue != nuArgValue {
		fmt.Fprintf(os.Stderr, "   ❌ Argument values do not match: %q vs %q\n", posixArgValue, nuArgValue)
		return false
	}

	fmt.Fprintf(os.Stderr, "   ✅ Arguments match: %q\n", posixArgValue)
	return true
}

func getPosixArgType(word *syntax.Word) string {
	if len(word.Parts) != 1 {
		return "ComplexWord"
	}
	switch part := word.Parts[0].(type) {
	case *syntax.Lit:
		return "String"
	case *syntax.SglQuoted:
		return "String"
	case *syntax.DblQuoted:
		if len(part.Parts) == 1 {
			if _, ok := part.Parts[0].(*syntax.Lit); ok {
				return "String"
			}
		}
		return "ComplexDblQuoted"
	default:
		return "Unknown"
	}
}

func posixArgTypeMatchesNuArgType(posixType, nuType string) bool {
	// Map POSIX argument types to Nushell types for comparison
	switch posixType {
	case "Name", "String":
		return nuType == "Name" || nuType == "String"
	default:
		return false
	}
}

func wordToString(word *syntax.Word) string {
	var sb strings.Builder
	for _, part := range word.Parts {
		switch x := part.(type) {
		case *syntax.Lit:
			sb.WriteString(x.Value)
		case *syntax.SglQuoted:
			sb.WriteString(x.Value)
		case *syntax.DblQuoted:
			for _, dqPart := range x.Parts {
				switch y := dqPart.(type) {
				case *syntax.Lit:
					sb.WriteString(y.Value)
				}
			}
		}
	}
	return sb.String()
}

func printNode(node syntax.Node, indent int) {
	nodeType := fmt.Sprintf("%T", node)
	var nodeValue string

	switch x := node.(type) {
	case *syntax.Lit:
		nodeValue = fmt.Sprintf(" (%q)", x.Value)
	case *syntax.Word:
		wordLit := wordToString(x)
		nodeValue = fmt.Sprintf(" (%q)", wordLit)
	case *syntax.ParamExp:
		nodeValue = fmt.Sprintf(" ($%s)", x.Param.Value)
	case *syntax.SglQuoted:
		nodeValue = fmt.Sprintf(" (%q)", x.Value)
	case *syntax.DblQuoted:
		wordLit := wordToString(&syntax.Word{Parts: []syntax.WordPart{x}})
		nodeValue = fmt.Sprintf(" (%q)", wordLit)
	}

	fmt.Fprintf(os.Stderr, "%s%s%s\n", strings.Repeat("  ", indent), nodeType, nodeValue)

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
	case *syntax.SglQuoted:
		// Single-quoted literals have no inner parts
	default:
		// Handle other node types if necessary
	}
}

func ParsePosixShell(snippet string) (syntax.Node, error) {
	parser := syntax.NewParser()
	return parser.Parse(strings.NewReader(snippet), "")
}

func ParseNu(snippet string) (map[string]interface{}, error) {
	fmt.Fprintf(os.Stderr, "Calling nushell-ast-printer with input: %q\n", snippet)

	cmd := exec.Command("nushell-ast-printer")
	cmd.Stdin = bytes.NewBufferString(snippet)

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		if stderr.Len() > 0 {
			fmt.Fprintf(os.Stderr, "nushell-ast-printer stderr output:\n%s\n", stderr.String())
		}

		var execErr *exec.Error
		if errors.As(err, &execErr) && errors.Is(execErr.Err, exec.ErrNotFound) {
			return nil, fmt.Errorf("the 'nushell-ast-printer' command was not found")
		}
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			return nil, fmt.Errorf("nushell-ast-printer failed with exit code %d: %v", exitErr.ExitCode(), err)
		}
		return nil, fmt.Errorf("unexpected error running nushell-ast-printer: %v", err)
	}

	output := stdout.String()
	fmt.Fprintf(os.Stderr, "nushell-ast-printer raw output:\n%s\n", output)

	var astMap map[string]interface{}
	if err := json.Unmarshal([]byte(output), &astMap); err != nil {
		return nil, fmt.Errorf("error unmarshalling JSON (output was %q): %v", output, err)
	}

	fmt.Fprintf(os.Stderr, "Successfully parsed Nushell AST\n")
	return astMap, nil
}
