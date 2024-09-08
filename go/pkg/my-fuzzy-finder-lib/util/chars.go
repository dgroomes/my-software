// THIS IS A COPY from https://github.com/junegunn/fzf/tree/8af0af3400fc36651b59a7e3f9a2bedd4a51daed
// MIT LICENSE

package util

import (
	"unicode"
	"unicode/utf8"
)

type Chars []rune

// ToChars converts byte array into rune array
func ToChars(bytes []byte) Chars {
	var runes []rune
	for i := 0; i < len(bytes); {
		r, sz := utf8.DecodeRune(bytes[i:])
		i += sz
		runes = append(runes, r)
	}
	return runes
}

func (chars Chars) Get(i int) rune {
	return []rune(chars)[i]
}

func (chars Chars) Length() int {
	return len(chars)
}

func (chars Chars) LeadingWhitespaces() int {
	whitespaces := 0
	for i := 0; i < chars.Length(); i++ {
		char := chars.Get(i)
		if !unicode.IsSpace(char) {
			break
		}
		whitespaces++
	}
	return whitespaces
}

func (chars Chars) TrailingWhitespaces() int {
	whitespaces := 0
	for i := chars.Length() - 1; i >= 0; i-- {
		char := chars.Get(i)
		if !unicode.IsSpace(char) {
			break
		}
		whitespaces++
	}
	return whitespaces
}

func (chars Chars) CopyRunes(dest []rune, from int) {
	for idx, b := range chars[from:][:len(dest)] {
		dest[idx] = b
	}
}
