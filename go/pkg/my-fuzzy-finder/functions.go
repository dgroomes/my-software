// THIS IS A COPY from https://github.com/junegunn/fzf/tree/8af0af3400fc36651b59a7e3f9a2bedd4a51daed
// MIT LICENSE

package main

import (
	"os"
	"strings"
	"unsafe"
)

func WriteTemporaryFile(data []string, printSep string) string {
	f, err := os.CreateTemp("", "fzf-temp-*")
	if err != nil {
		// Unable to create temporary file
		// FIXME: Should we terminate the program?
		return ""
	}
	defer f.Close()

	f.WriteString(strings.Join(data, printSep))
	f.WriteString(printSep)
	return f.Name()
}

func removeFiles(files []string) {
	for _, filename := range files {
		os.Remove(filename)
	}
}

func stringBytes(data string) []byte {
	return unsafe.Slice(unsafe.StringData(data), len(data))
}

func byteString(data []byte) string {
	return unsafe.String(unsafe.SliceData(data), len(data))
}
