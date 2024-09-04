// THIS IS A COPY from https://github.com/junegunn/fzf/tree/8af0af3400fc36651b59a7e3f9a2bedd4a51daed
// MIT LICENSE

package my_fuzzy_finder

import (
	"fmt"
	"my-software/pkg/my-fuzzy-finder-lib/util"
)

// Range represents nth-expression
type Range struct {
	begin int
	end   int
}

// Token contains the tokenized part of the strings and its prefix length
type Token struct {
	text         *util.Chars
	prefixLength int32
}

// String returns the string representation of a Token.
func (t Token) String() string {
	return fmt.Sprintf("Token{text: %s, prefixLength: %d}", t.text, t.prefixLength)
}
