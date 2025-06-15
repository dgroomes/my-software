package main

import (
	"crypto/tls"
	"crypto/x509"
	_ "embed"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"syscall"
	"time"
	"unsafe"
)

/*
#cgo LDFLAGS: -lsandbox
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

extern int sandbox_init_with_parameters(const char *profile, uint64_t flags, const char *const parameters[], char **errorbuf);
extern void sandbox_free_error(char *errorbuf);

// This is our bridge from Go to the native 'sandbox_init_with_parameters' C function.
int sandbox_init_go_bridge(const char* profile, const char* project_dir, const char* claude_json_path, const char* claude_dir, const char* shell_debug_log_path) {

    // This hardcoding is a code smell but I've experimented with parameterizing on a map of parameters but that
    // balloons the amount of code that does C things (malloc from Go, etc) and ultimately increases the likelihood
    // that I make a C mistake (scary). Let's keep it legible and non-DRY for now.
    const char* params[] = {
        "PROJECT_DIR", project_dir,
        "CLAUDE_JSON_PATH", claude_json_path,
        "CLAUDE_DIR", claude_dir,
        "SHELL_DEBUG_LOG_PATH", shell_debug_log_path,
        NULL
    };
    char* error_buf = NULL;

    int result = sandbox_init_with_parameters(profile, 0, params, &error_buf);

    if (result != 0 && error_buf != NULL) {
        fprintf(stderr, "Sandbox error: %s\n", error_buf);
        sandbox_free_error(error_buf);
    }

    return result;
}
*/
import "C"

const (
	ProxyHost   = "127.0.0.1"
	ProxyPort   = "9051"
	HTTPTimeout = 4 * time.Second
)

// Embed the Seatbelt profile from the resources directory
//
//go:embed resources/claude.sb
var seatbeltProfile string

// getCertPath returns the full path to the mitmproxy certificate
func getCertPath() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}
	return filepath.Join(home, ".config", "claude-proxy", "mitmproxy-ca-cert.pem"), nil
}

// checkProxyRunning verifies the proxy is accessible on the expected port
func checkProxyRunning() error {
	client := &http.Client{
		Timeout: HTTPTimeout,
		// Don't follow redirects for this basic check
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}

	resp, err := client.Head(fmt.Sprintf("http://%s:%s", ProxyHost, ProxyPort))
	if err != nil {
		return fmt.Errorf("claude-proxy is not running. Start the proxy before using claude-sandboxed. %w", err)
	}
	defer resp.Body.Close()

	return nil
}

// checkProxyConfiguration performs thorough checks on the proxy setup
func checkProxyConfiguration() (bool, bool, bool, error) {
	certPath, err := getCertPath()
	if err != nil {
		return false, false, false, err
	}

	// Check if certificate exists
	if _, err := os.Stat(certPath); os.IsNotExist(err) {
		return false, false, false, fmt.Errorf("mitmproxy certificate not found at %s. Please start claude-proxy first", certPath)
	}

	// Load the certificate
	certData, err := os.ReadFile(certPath)
	if err != nil {
		return false, false, false, fmt.Errorf("failed to read certificate: %w", err)
	}

	// Create a certificate pool with only the mitmproxy CA
	certPool := x509.NewCertPool()
	if !certPool.AppendCertsFromPEM(certData) {
		return false, false, false, fmt.Errorf("failed to add certificate to pool")
	}

	// Create HTTP client with proxy and custom CA
	client := &http.Client{
		Timeout: HTTPTimeout,
		Transport: &http.Transport{
			Proxy: http.ProxyURL(&url.URL{
				Scheme: "http",
				Host:   fmt.Sprintf("%s:%s", ProxyHost, ProxyPort),
			}),
			TLSClientConfig: &tls.Config{
				RootCAs: certPool,
			},
		},
	}

	// Test 1: Verify api.anthropic.com is blocked without proxy
	anthropicBlocked := false
	clientDirect := &http.Client{
		Timeout: HTTPTimeout,
	}
	_, err = clientDirect.Head("https://api.anthropic.com")
	if err != nil {
		anthropicBlocked = true
	}

	// Test 2: Verify api.anthropic.com is accessible through proxy
	anthropicViaProxyAllowed := false
	resp, err := client.Head("https://api.anthropic.com")
	if err == nil {
		resp.Body.Close()
		anthropicViaProxyAllowed = true
	}

	// Test 3: Verify mozilla.org is blocked
	mozillaBlocked := false
	resp2, err := client.Head("https://mozilla.org")
	if err != nil {
		// Connection error counts as blocked
		mozillaBlocked = true
	} else {
		defer resp2.Body.Close()
		if resp2.StatusCode == http.StatusForbidden {
			mozillaBlocked = true
		}
	}

	return anthropicBlocked, anthropicViaProxyAllowed, mozillaBlocked, nil
}

// initializeSandbox uses sandbox_init to apply the Seatbelt profile
func initializeSandbox(projectDir string) error {
	// Get home directory for claude.json path and claude directory
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get home directory: %w", err)
	}
	claudeJSONPath := filepath.Join(homeDir, ".claude.json")
	claudeDir := filepath.Join(homeDir, ".claude")
	shellDebugLogPath := filepath.Join(homeDir, ".shell-debug.log")

	// Convert Go strings to C strings
	cProfile := C.CString(seatbeltProfile)
	defer C.free(unsafe.Pointer(cProfile))

	cProjectDir := C.CString(projectDir)
	defer C.free(unsafe.Pointer(cProjectDir))

	cClaudeJSONPath := C.CString(claudeJSONPath)
	defer C.free(unsafe.Pointer(cClaudeJSONPath))

	cClaudeDir := C.CString(claudeDir)
	defer C.free(unsafe.Pointer(cClaudeDir))

	cShellDebugLogPath := C.CString(shellDebugLogPath)
	defer C.free(unsafe.Pointer(cShellDebugLogPath))

	result := C.sandbox_init_go_bridge(cProfile, cProjectDir, cClaudeJSONPath, cClaudeDir, cShellDebugLogPath)

	if result != 0 {
		return fmt.Errorf("sandbox_init failed with code %d", result)
	}

	return nil
}

// getProxyEnv returns the environment variables needed for Node.js to use the proxy
func getProxyEnv() (map[string]string, error) {
	certPath, err := getCertPath()
	if err != nil {
		return nil, err
	}

	return map[string]string{
		"HTTP_PROXY":          fmt.Sprintf("http://%s:%s", ProxyHost, ProxyPort),
		"HTTPS_PROXY":         fmt.Sprintf("http://%s:%s", ProxyHost, ProxyPort),
		"NODE_EXTRA_CA_CERTS": certPath,
	}, nil
}

func main() {
	// Pre-check that the proxy is running (silently)
	if err := checkProxyRunning(); err != nil {
		fmt.Fprintf(os.Stderr, "❌ Error: %v\n", err)
		os.Exit(1)
	}

	// Display initial status
	fmt.Println("✅ Proxy server running")

	// Get current working directory for the sandbox
	projectDir, err := os.Getwd()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Error getting current directory: %v\n", err)
		os.Exit(1)
	}

	// Initialize the sandbox BEFORE network checks
	fmt.Println("Sandbox applied. Running checks...")
	if err := initializeSandbox(projectDir); err != nil {
		fmt.Fprintf(os.Stderr, "❌ Error initializing sandbox: %v\n", err)
		os.Exit(1)
	}

	// Check proxy configuration AFTER sandbox is applied
	anthropicBlocked, anthropicViaProxyAllowed, mozillaBlocked, err := checkProxyConfiguration()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Error: %v\n", err)
		os.Exit(1)
	}

	// Validate the checks
	if !anthropicBlocked {
		fmt.Fprintf(os.Stderr, "❌ Error: api.anthropic.com is not properly blocked (direct access should be denied)\n")
		os.Exit(1)
	}
	if !anthropicViaProxyAllowed {
		fmt.Fprintf(os.Stderr, "❌ Error: api.anthropic.com is not accessible through proxy\n")
		os.Exit(1)
	}
	if !mozillaBlocked {
		fmt.Fprintf(os.Stderr, "❌ Error: mozilla.org is not properly blocked by proxy\n")
		os.Exit(1)
	}

	// Display check results as specified in README
	fmt.Println("✅ Remote calls blocked")
	fmt.Println("✅ Anthropic calls via proxy allowed")
	fmt.Println("✅ Non-Anthropic calls via proxy blocked")
	fmt.Println()

	// Find the claude binary
	claudePath, err := exec.LookPath("claude")
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Error finding claude binary: %v\n", err)
		os.Exit(1)
	}

	// Prepare environment with proxy settings
	env := os.Environ()
	proxyEnv, err := getProxyEnv()
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Error getting proxy environment: %v\n", err)
		os.Exit(1)
	}
	for k, v := range proxyEnv {
		env = append(env, fmt.Sprintf("%s=%s", k, v))
	}

	// Replace this process with Claude Code
	err = syscall.Exec(claudePath, []string{"claude"}, env)
	if err != nil {
		fmt.Fprintf(os.Stderr, "❌ Error executing Claude Code: %v\n", err)
		os.Exit(1)
	}
}
