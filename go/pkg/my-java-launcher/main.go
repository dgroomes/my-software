// 'my-java-launcher' launches a program based on the properties of a manifest file ('my-java-launcher.json').
package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"syscall"
)

// Manifest represents the structure of the manifest file: 'my-java-launcher.json'
type Manifest struct {
	ProgramType       string            `json:"program_type"`
	Entrypoint        string            `json:"entrypoint"`
	DryRun            bool              `json:"dry_run"`
	JavaConfiguration JavaConfiguration `json:"java_configuration"`
}

type JavaConfiguration struct {
	JavaVersion      int               `json:"java_version"`
	Classpath        []string          `json:"classpath"`
	SystemProperties map[string]string `json:"system_properties"`
	DebugOptions     DebugOptions      `json:"debug_options"`
}

type DebugOptions struct {
	RemoteDebugging bool `json:"remote_debugging"`
	DebugPort       int  `json:"debug_port"`
	SuspendOnStart  bool `json:"suspend_on_start"`
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
		fatal(fmt.Sprintf("[my-java-launcher error] Unable to determine the executable path: %v", err))
	}
	executablePath, err = filepath.EvalSymlinks(executablePath)
	if err != nil {
		fatal(fmt.Sprintf("[my-java-launcher error] Unable to resolve symlinks for executable path: %v", err))
	}
	executableDir := filepath.Dir(executablePath)

	manifestPath := filepath.Join(executableDir, "my-java-launcher.json")
	manifestData, err := os.ReadFile(manifestPath)
	if err != nil {
		if os.IsNotExist(err) {
			fatal(fmt.Sprintf("[my-java-launcher error] Manifest file not found. A 'my-java-launcher.json' file must be present in the same directory as 'my-java-launcher'"))
		} else {
			fatal(fmt.Sprintf("[my-java-launcher error] Unexpected error while reading the manifest file: %v", err))
		}
	}

	var manifest Manifest
	err = json.Unmarshal(manifestData, &manifest)
	if err != nil {
		fatal(fmt.Sprintf("[my-java-launcher error] JSON parsing error when reading the manifest file: %v", err))
	}

	if manifest.ProgramType != "java" {
		fatal(fmt.Sprintf("[my-java-launcher error] Only Java programs are supported but 'program_type' was set to '%s'", manifest.ProgramType))
	}
	if manifest.Entrypoint == "" {
		fatal(fmt.Sprintf("[my-java-launcher error] 'entrypoint' is required in the manifest"))
	}
	if manifest.JavaConfiguration.JavaVersion != 11 && manifest.JavaConfiguration.JavaVersion != 17 && manifest.JavaConfiguration.JavaVersion != 21 {
		fatal(fmt.Sprintf("[my-java-launcher error] 'java_version' must be one of [11, 17, 21]"))
	}
	if len(manifest.JavaConfiguration.Classpath) == 0 {
		fatal(fmt.Sprintf("[my-java-launcher error] 'classpath' must contain at least one entry"))
	}

	// Resolve classpath entries to absolute paths
	for i, cp := range manifest.JavaConfiguration.Classpath {
		absPath := filepath.Join(executableDir, cp)
		absPath, err = filepath.Abs(absPath)
		if err != nil {
			fatal(fmt.Sprintf("[my-java-launcher error] Unable to resolve classpath entry '%s' to an absolute path: %v", cp, err))
		}
		manifest.JavaConfiguration.Classpath[i] = absPath
	}

	// Search for the appropriate Java executable. This search algorithm relies on a conventional approach:
	//
	//   * Java 11 should be identified by an environment variable JAVA_11_HOME
	//   * Java 17 should be identified by an environment variable JAVA_17_HOME
	//   * etc.
	envVarName := fmt.Sprintf("JAVA_%d_HOME", manifest.JavaConfiguration.JavaVersion)
	javaHome, exists := os.LookupEnv(envVarName)
	if !exists {
		fatal(fmt.Sprintf("[my-java-launcher error] The manifest requires Java %d, but this version of Java could not be located on the system. The environment variable '%s' must be set", manifest.JavaConfiguration.JavaVersion, envVarName))
	}

	if _, err := os.Stat(javaHome); os.IsNotExist(err) {
		fatal(fmt.Sprintf("[my-java-launcher error] The environment variable '%s' points to non-existent directory '%s'", envVarName, javaHome))
	}

	javaExecutable := filepath.Join(javaHome, "bin", "java")
	if _, err := os.Stat(javaExecutable); os.IsNotExist(err) {
		fatal(fmt.Sprintf("[my-java-launcher error] 'java' executable not found at '%s'", javaExecutable))
	}

	javaCmd := buildJavaCommand(&manifest)

	if manifest.DryRun {
		fmt.Println("[my-java-launcher dry run]")
		fmt.Println("Executable: ", javaExecutable)
		fmt.Println("Command: ", strings.Join(javaCmd, " "))
		return
	}

	err = syscall.Exec(javaExecutable, javaCmd, os.Environ())
	if err != nil {
		fatal(fmt.Sprintf("[my-java-launcher error] Something went wrong while trying to 'exec' the program: %v", err))
	}
}

// buildJavaCommand constructs the 'java' command with all necessary arguments. Specifically, the command will have the
// following components in this order:
//
//   - System properties will be formatted as '-Dkey=value'
//   - Classpath entries will be formatted as '-classpath path1:path2:...'.
//   - Debug options will be formatted as '-agentlib...'
//   - The entrypoint (the class containing the 'public static void main' method) will be the last argument
func buildJavaCommand(manifest *Manifest) []string {
	cmd := []string{"java"}

	if len(manifest.JavaConfiguration.Classpath) > 0 {
		cmd = append(cmd, "-classpath", strings.Join(manifest.JavaConfiguration.Classpath, string(os.PathListSeparator)))
	}

	if manifest.JavaConfiguration.DebugOptions.RemoteDebugging {
		suspend := "n"
		if manifest.JavaConfiguration.DebugOptions.SuspendOnStart {
			suspend = "y"
		}

		debugOpts := fmt.Sprintf("-agentlib:jdwp=transport=dt_socket,server=y,suspend=%s,address=*:%d",
			suspend,
			manifest.JavaConfiguration.DebugOptions.DebugPort)
		cmd = append(cmd, debugOpts)
	}

	for key, value := range manifest.JavaConfiguration.SystemProperties {
		cmd = append(cmd, fmt.Sprintf("-D%s=%s", key, value))
	}

	cmd = append(cmd, manifest.Entrypoint)
	cmd = append(cmd, os.Args[1:]...)
	return cmd
}
