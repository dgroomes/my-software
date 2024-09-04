// Miscellaneous code that I need from 'fzf' but that is brought in piece meal instead of by copy/pasting a whole file
// which would then bring in things that cascade into bringing in other things.
//
// Most of this code is from https://github.com/junegunn/fzf/tree/8af0af3400fc36651b59a7e3f9a2bedd4a51daed
// MIT LICENSE
package main

// From 'options.go'

// Sort criteria
type criterion int

const (
	byScore criterion = iota
	byChunk
	byLength
	byBegin
	byEnd
)

// Case denotes case-sensitivity of search
type Case int

// Case-sensitivities
const (
	CaseSmart Case = iota
	CaseIgnore
	CaseRespect
)
