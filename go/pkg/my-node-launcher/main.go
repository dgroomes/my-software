// 'my-node-launcher' launches a Node.js program based on the properties of a manifest file ('my-node-launcher.json').
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"syscall"
)

// Manifest represents the structure of the manifest file: 'my-node-launcher.json'
// Is it redundant to have 'entrypoint' because 'package.json' is already designed for that? Or, am I wanting to eject
// from that? I think the entrypoint file is pretty core to what I'm doing here so I feel like I should own this.
type Manifest struct {
	Entrypoint      string            `json:"entrypoint"`
	DryRun          bool              `json:"dry_run"`
	NodeVersion     int               `json:"node_version"`
	NodeArgs        []string          `json:"node_args"`
}

//go:noreturn
func fatal(msg string) {
	//goland:noinspection GoUnhandledErrorResult
	fmt.Fprintln(os.Stderr, msg)
	os.Exit(1)
}

func main() {
	executablePath, err := os.Executable()
	if err != nil {
		fatal(fmt.Sprintf("[my-node-launcher error] Unable to determine the executable path: %v", err))
	}
	executablePath, err = filepath.EvalSymlinks(executablePath)
	if err != nil {
		fatal(fmt.Sprintf("[my-node-launcher error] Unable to resolve symlinks for executable path: %v", err))
	}
	executableDir := filepath.Dir(executablePath)

	manifestPath := filepath.Join(executableDir, "my-node-launcher.json")
	manifestData, err := os.ReadFile(manifestPath)
	if err != nil {
		if os.IsNotExist(err) {
			fatal(fmt.Sprintf("[my-node-launcher error] Manifest file not found. A 'my-node-launcher.json' file must be present in the same directory as 'my-node-launcher'"))
		} else {
			fatal(fmt.Sprintf("[my-node-launcher error] Unexpected error while reading the manifest file: %v", err))
		}
	}

	var manifest Manifest
	err = json.Unmarshal(manifestData, &manifest)
	if err != nil {
		fatal(fmt.Sprintf("[my-node-launcher error] JSON parsing error when reading the manifest file: %v", err))
	}

	if manifest.Entrypoint == "" {
		fatal(fmt.Sprintf("[my-node-launcher error] 'entrypoint' is required in the manifest"))
	}
	if manifest.NodeVersion <= 0 {
		fatal(fmt.Sprintf("[my-node-launcher error] 'node_version' must be specified"))
	}

	// Resolve entrypoint to absolute path
	entrypointPath := filepath.Join(executableDir, manifest.Entrypoint)
	entrypointPath, err = filepath.Abs(entrypointPath)
	if err != nil {
		fatal(fmt.Sprintf("[my-node-launcher error] Unable to resolve entrypoint '%s' to an absolute path: %v", manifest.Entrypoint, err))
	}

	// Check if entrypoint exists
	if _, err := os.Stat(entrypointPath); os.IsNotExist(err) {
		fatal(fmt.Sprintf("[my-node-launcher error] Entrypoint file '%s' does not exist", entrypointPath))
	}

	// Search for the appropriate Node executable based on environment variables
	envVarName := fmt.Sprintf("NODEJS_%d_HOME", manifest.NodeVersion)
	nodeHome, exists := os.LookupEnv(envVarName)
	if !exists {
		fatal(fmt.Sprintf("[my-node-launcher error] The manifest requires Node %d, but this version of Node could not be located. The environment variable '%s' must be set to the Node installation directory", manifest.NodeVersion, envVarName))
	}

	if _, err := os.Stat(nodeHome); os.IsNotExist(err) {
		fatal(fmt.Sprintf("[my-node-launcher error] The environment variable '%s' points to non-existent directory '%s'", envVarName, nodeHome))
	}

	nodeExecutable := filepath.Join(nodeHome, "bin", "node")
	if _, err := os.Stat(nodeExecutable); os.IsNotExist(err) {
		fatal(fmt.Sprintf("[my-node-launcher error] 'node' executable not found at '%s'", nodeExecutable))
	}

	nodeCmd := buildNodeCommand(&manifest, entrypointPath)

	if manifest.DryRun {
		fmt.Println("[my-node-launcher dry run]")
		fmt.Println("Executable: ", nodeExecutable)
		fmt.Println("Command: ", strings.Join(nodeCmd, " "))
		fmt.Println("Node runtime arguments:", strings.Join(manifest.NodeArgs, " "))
		return
	}

	err = syscall.Exec(nodeExecutable, nodeCmd, os.Environ())
	if err != nil {
		fatal(fmt.Sprintf("[my-node-launcher error] Something went wrong while trying to 'exec' the program: %v", err))
	}
}

// buildNodeCommand constructs the 'node' command with all necessary arguments.
// The command includes:
//   - The node executable
//   - Any Node.js runtime arguments from the manifest
//   - The entrypoint JavaScript file
//   - Any program arguments
func buildNodeCommand(manifest *Manifest, entrypointPath string) []string {
	cmd := []string{"node"}

	// Add Node.js runtime arguments from manifest
	if len(manifest.NodeArgs) > 0 {
		cmd = append(cmd, manifest.NodeArgs...)
	}

	// Add the entrypoint file
	cmd = append(cmd, entrypointPath)

	// Add any command line arguments passed to the launcher
	cmd = append(cmd, os.Args[1:]...)

	return cmd
}
