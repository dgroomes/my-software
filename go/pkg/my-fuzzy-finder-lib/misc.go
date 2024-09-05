// Miscellaneous code that I need from 'fzf' but that is brought in piece meal instead of by copy/pasting a whole file
// which would then bring in things that cascade into bringing in other things.
//
// Most of this code is from https://github.com/junegunn/fzf/tree/8af0af3400fc36651b59a7e3f9a2bedd4a51daed
// MIT LICENSE
package my_fuzzy_finder

import "my-software/pkg/my-fuzzy-finder-lib/util"

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

// Other

type Item struct {
	text util.Chars
}

// Index returns ordinal index of the Item
func (item *Item) Index() int32 {
	return item.text.Index
}

func (item *Item) TrimLength() uint16 {
	return item.text.TrimLength()
}
