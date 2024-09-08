// THIS IS A COPY from https://github.com/junegunn/fzf/tree/8af0af3400fc36651b59a7e3f9a2bedd4a51daed
// MIT LICENSE

package algo

import (
	"my-software/pkg/my-fuzzy-finder-lib/util"
	"strings"
	"unicode"
)

var delimiterChars = "/,:;|"

const whiteChars = " \t\n\v\f\r\x85\xA0"

func indexAt(index int, max int, forward bool) int {
	if forward {
		return index
	}
	return max - index - 1
}

// Result contains the results of running a match function.
type Result struct {
	Start int
	End   int
}

const (
	scoreMatch = 16
	// We prefer matches at the beginning of a word, but the bonus should not be
	// too great to prevent the longer acronym matches from always winning over
	// shorter fuzzy matches. The bonus point here was specifically chosen that
	// the bonus is cancelled when the gap between the acronyms grows over
	// 8 characters, which is approximately the average length of the words found
	// in web2 dictionary and my file system.
	bonusBoundary = scoreMatch / 2
)

var (
	// Extra bonus for word boundary after whitespace character or beginning of the string
	bonusBoundaryWhite int16 = bonusBoundary + 2

	// A minor optimization that can give 15%+ performance boost
	asciiCharClasses [unicode.MaxASCII + 1]charClass

	// A minor optimization that can give yet another 5% performance boost
	bonusMatrix [charNumber + 1][charNumber + 1]int16
)

type charClass int

const (
	charWhite charClass = iota
	charNonWord
	charDelimiter
	charLower
	charUpper
	charLetter
	charNumber
)

func init() {
	for i := 0; i <= unicode.MaxASCII; i++ {
		char := rune(i)
		c := charNonWord
		if char >= 'a' && char <= 'z' {
			c = charLower
		} else if char >= 'A' && char <= 'Z' {
			c = charUpper
		} else if char >= '0' && char <= '9' {
			c = charNumber
		} else if strings.ContainsRune(whiteChars, char) {
			c = charWhite
		} else if strings.ContainsRune(delimiterChars, char) {
			c = charDelimiter
		}
		asciiCharClasses[i] = c
	}
}

func charClassOfNonAscii(char rune) charClass {
	if unicode.IsLower(char) {
		return charLower
	} else if unicode.IsUpper(char) {
		return charUpper
	} else if unicode.IsNumber(char) {
		return charNumber
	} else if unicode.IsLetter(char) {
		return charLetter
	} else if unicode.IsSpace(char) {
		return charWhite
	} else if strings.ContainsRune(delimiterChars, char) {
		return charDelimiter
	}
	return charNonWord
}

func charClassOf(char rune) charClass {
	if char <= unicode.MaxASCII {
		return asciiCharClasses[char]
	}
	return charClassOfNonAscii(char)
}

func bonusAt(input util.Chars, idx int) int16 {
	if idx == 0 {
		return bonusBoundaryWhite
	}
	return bonusMatrix[charClassOf(input.Get(idx-1))][charClassOf(input.Get(idx))]
}

// Algo functions make two assumptions
type Algo func(input util.Chars, pattern []rune) (Result, *[]int)

func FuzzyMatch(input util.Chars, pattern []rune) (Result, *[]int) {
	M := len(pattern)
	N := input.Length()
	if M > N {
		return Result{-1, -1}, nil
	}

	F := make([]int32, M)
	T := make([]int32, N)
	input.CopyRunes(T, 0)

	pidx := 0
	pchar := pattern[0]
	for off, char := range T {
		char = unicode.ToLower(char)
		T[off] = char

		if char == pchar {
			F[pidx] = int32(off)
			pidx++
			if pidx == M {
				break
			}
			pchar = pattern[pidx]
		}
	}
	if pidx != M {
		return Result{-1, -1}, nil
	}

	result := Result{int(F[0]), int(F[M-1]) + 1}

	pos := make([]int, M)
	for i := 0; i < M; i++ {
		pos[i] = int(F[i])
	}

	return result, &pos
}

// ExactMatchNaive is a basic string searching algorithm that is case
// / insensitive. Although naive, it still performs better than the combination
// of strings.ToLower + strings.Index for typical fzf use cases where input
// strings and patterns are not very long.
//
// Since 0.15.0, this function searches for the match with the highest
// bonus point, instead of stopping immediately after finding the first match.
// The solution is much cheaper since there is only one possible alignment of
// the pattern.
func ExactMatchNaive(text util.Chars, pattern []rune) (Result, *[]int) {
	return exactMatchNaive(false, text, pattern)
}

func ExactMatchBoundary(text util.Chars, pattern []rune) (Result, *[]int) {
	return exactMatchNaive(true, text, pattern)
}

func exactMatchNaive(boundaryCheck bool, input util.Chars, pattern []rune) (Result, *[]int) {
	if len(pattern) == 0 {
		return Result{0, 0}, nil
	}

	lenInput := input.Length()
	lenPattern := len(pattern)

	// For simplicity, only look at the bonus at the first character position
	pidx := 0
	bestPos, bonus, bestBonus := -1, int16(0), int16(-1)
	for index := 0; index < lenInput; index++ {
		index_ := indexAt(index, lenInput, true)
		char := input.Get(index_)
		if char >= 'A' && char <= 'Z' {
			char += 32
		} else if char > unicode.MaxASCII {
			char = unicode.To(unicode.LowerCase, char)
		}
		pidx_ := indexAt(pidx, lenPattern, true)
		pchar := pattern[pidx_]
		ok := pchar == char
		if ok {
			if pidx_ == 0 {
				bonus = bonusAt(input, index_)
			}
			if boundaryCheck {
				ok = bonus >= bonusBoundary
				if ok && pidx_ == 0 {
					ok = index_ == 0 || charClassOf(input.Get(index_-1)) <= charDelimiter
				}
				if ok && pidx_ == len(pattern)-1 {
					ok = index_ == lenInput-1 || charClassOf(input.Get(index_+1)) <= charDelimiter
				}
			}
		}
		if ok {
			pidx++
			if pidx == lenPattern {
				if bonus > bestBonus {
					bestPos, bestBonus = index, bonus
				}
				if bonus >= bonusBoundary {
					break
				}
				index -= pidx - 1
				pidx, bonus = 0, 0
			}
		} else {
			index -= pidx
			pidx, bonus = 0, 0
		}
	}
	if bestPos >= 0 {
		var sidx, eidx int
		if true {
			sidx = bestPos - lenPattern + 1
			eidx = bestPos + 1
		} else {
			sidx = lenInput - (bestPos + 1)
			eidx = lenInput - (bestPos - lenPattern + 1)
		}
		return Result{sidx, eidx}, nil
	}
	return Result{-1, -1}, nil
}

// PrefixMatch performs prefix-match
func PrefixMatch(text util.Chars, pattern []rune) (Result, *[]int) {
	if len(pattern) == 0 {
		return Result{0, 0}, nil
	}

	trimmedLen := 0
	if !unicode.IsSpace(pattern[0]) {
		trimmedLen = text.LeadingWhitespaces()
	}

	if text.Length()-trimmedLen < len(pattern) {
		return Result{-1, -1}, nil
	}

	for index, r := range pattern {
		char := text.Get(trimmedLen + index)
		char = unicode.ToLower(char)
		if char != r {
			return Result{-1, -1}, nil
		}
	}
	lenPattern := len(pattern)
	return Result{trimmedLen, trimmedLen + lenPattern}, nil
}

// SuffixMatch performs suffix-match
func SuffixMatch(text util.Chars, pattern []rune) (Result, *[]int) {
	lenRunes := text.Length()
	trimmedLen := lenRunes
	if len(pattern) == 0 || !unicode.IsSpace(pattern[len(pattern)-1]) {
		trimmedLen -= text.TrailingWhitespaces()
	}
	if len(pattern) == 0 {
		return Result{trimmedLen, trimmedLen}, nil
	}
	diff := trimmedLen - len(pattern)
	if diff < 0 {
		return Result{-1, -1}, nil
	}

	for index, r := range pattern {
		char := text.Get(index + diff)
		char = unicode.ToLower(char)
		if char != r {
			return Result{-1, -1}, nil
		}
	}
	lenPattern := len(pattern)
	sidx := trimmedLen - lenPattern
	eidx := trimmedLen
	return Result{sidx, eidx}, nil
}

// EqualMatch performs equal-match
func EqualMatch(text util.Chars, pattern []rune) (Result, *[]int) {
	lenPattern := len(pattern)
	if lenPattern == 0 {
		return Result{-1, -1}, nil
	}

	// Strip leading whitespaces
	trimmedLen := 0
	if !unicode.IsSpace(pattern[0]) {
		trimmedLen = text.LeadingWhitespaces()
	}

	// Strip trailing whitespaces
	trimmedEndLen := 0
	if !unicode.IsSpace(pattern[lenPattern-1]) {
		trimmedEndLen = text.TrailingWhitespaces()
	}

	if text.Length()-trimmedLen-trimmedEndLen != lenPattern {
		return Result{-1, -1}, nil
	}
	match := true

	runesStr := string(text[trimmedLen : len(text)-trimmedEndLen])
	runesStr = strings.ToLower(runesStr)
	match = runesStr == string(pattern)

	if match {
		return Result{trimmedLen, trimmedLen + lenPattern}, nil
	}
	return Result{-1, -1}, nil
}
