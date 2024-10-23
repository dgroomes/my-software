package main

import (
	"testing"
)

func TestParserCompatibility(t *testing.T) {
	tests := map[string]struct {
		snippet        string
		wantCompatible bool
	}{
		"command only": {
			snippet:        "echo",
			wantCompatible: true,
		},
		"command and word arg": {
			snippet:        "echo hi",
			wantCompatible: true,
		},
		"command and quoted arg": {
			snippet:        "echo 'hi there'",
			wantCompatible: true,
		},
		"variable substitution": {
			snippet:        "echo $USER",
			wantCompatible: false,
		},
		"pipe command": {
			snippet:        "ls | grep foo",
			wantCompatible: false,
		},
	}

	for name, tc := range tests {
		t.Run(name, func(t *testing.T) {
			compatible, err := CompatibleSnippet(tc.snippet)
			if err != nil {
				t.Errorf("Something went wrong: %v", err)
			}
			if compatible != tc.wantCompatible {
				t.Errorf("Compatibility check failed: got %v, want %v", compatible, tc.wantCompatible)
			}
		})
	}
}
