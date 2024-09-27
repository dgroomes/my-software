// See the README for more information about this program.

package main

import (
	"go/ast"
	"go/parser"
	"go/printer"
	"go/token"
	"io"
	"log"
	"os"
)

func main() {
	// Read the input from stdin
	src, err := io.ReadAll(os.Stdin)
	if err != nil {
		log.Fatalf("Failed to read input: %v\n", err)
	}

	// Create a new token file set
	fset := token.NewFileSet()

	// Parse the source code
	file, err := parser.ParseFile(fset, "", src, parser.ParseComments)
	if err != nil {
		log.Fatalf("Failed to parse Go code: %v\n", err)
	}

	// Walk the AST and strip function bodies
	for _, decl := range file.Decls {
		if funcDecl, ok := decl.(*ast.FuncDecl); ok {
			// Replace the function body with an empty block containing a comment
			funcDecl.Body = &ast.BlockStmt{
				Lbrace: funcDecl.Body.Lbrace,
				Rbrace: funcDecl.Body.Rbrace,
				List: []ast.Stmt{
					&ast.ExprStmt{
						X: &ast.Ident{
							Name: "// OMITTED",
						},
					},
				},
			}
		}
	}

	// Print the modified code to stdout
	err = printer.Fprint(os.Stdout, fset, file)
	if err != nil {
		log.Fatalf("Failed to print modified code: %v\n", err)
	}
}
