// This was copied from 'fzf' and pared down and restructured for my needs: https://github.com/junegunn/fzf/tree/8af0af3400fc36651b59a7e3f9a2bedd4a51daed
// MIT LICENSE

package my_fuzzy_finder

import (
	"fmt"
	"regexp"
	"slices"
	"strings"
	"unicode"
)

type Match struct {
	Index     int
	Positions []int
}

func MatchOne(query string, item string) (bool, []int) {
	pattern := BuildPattern(query)
	if ok, positions := pattern.MatchItem(item); ok {
		return true, positions
	}

	return false, nil
}

func MatchAll(query string, items []string) []Match {
	pattern := BuildPattern(query)
	var matches []Match

	for i, item := range items {
		if ok, positions := pattern.MatchItem(item); ok {
			matches = append(matches, Match{
				Index:     i,
				Positions: positions,
			})
		}
	}
	return matches
}

var delimiterChars = "/,:;|"

// Result contains the results of running a match function.
type Result struct {
	Start int
	End   int
}

// Algo functions make two assumptions
type Algo func(input []rune, pattern []rune) (Result, *[]int)

func FuzzyMatch(input []rune, pattern []rune) (Result, *[]int) {
	M := len(pattern)
	N := len(input)
	if M > N {
		return Result{-1, -1}, nil
	}

	F := make([]int32, M)

	pidx := 0
	pchar := pattern[0]
	for off, char := range input {
		char = unicode.ToLower(char)
		input[off] = char

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

func ExactMatch(input string, pattern []rune, checkBoundary bool) (Result, *[]int) {
	if len(pattern) == 0 {
		return Result{0, 0}, nil
	}

	lower := strings.ToLower(input)
	patternStr := strings.ToLower(string(pattern))

	for i := 0; i < len(lower); i++ {
		if strings.HasPrefix(lower[i:], patternStr) {
			if !checkBoundary || (isWordBoundary(input, i) && isWordBoundary(input, i+len(pattern))) {
				end := i + len(pattern)
				positions := make([]int, len(pattern))
				for j := range positions {
					positions[j] = i + j
				}
				return Result{i, end}, &positions
			}
		}
	}

	return Result{-1, -1}, nil
}

func isWordBoundary(text string, index int) bool {
	if index == 0 || index == len(text) {
		return true
	}
	return isDelimiter(rune(text[index-1])) || isDelimiter(rune(text[index]))
}

func isDelimiter(char rune) bool {
	return strings.ContainsRune(delimiterChars, char) || unicode.IsSpace(char)
}

// PrefixMatch performs prefix-match
func PrefixMatch(input []rune, pattern []rune) (Result, *[]int) {
	if len(pattern) == 0 {
		return Result{0, 0}, nil
	}

	trimmedLen := 0
	if !unicode.IsSpace(pattern[0]) {
		trimmedLen = LeadingWhitespaces(input)
	}

	if len(input)-trimmedLen < len(pattern) {
		return Result{-1, -1}, nil
	}

	for index, r := range pattern {
		char := input[trimmedLen+index]
		char = unicode.ToLower(char)
		if char != r {
			return Result{-1, -1}, nil
		}
	}
	lenPattern := len(pattern)
	return Result{trimmedLen, trimmedLen + lenPattern}, nil
}

// SuffixMatch performs suffix-match
func SuffixMatch(input Chars, pattern []rune) (Result, *[]int) {
	lenRunes := input.Length()
	trimmedLen := lenRunes
	if len(pattern) == 0 || !unicode.IsSpace(pattern[len(pattern)-1]) {
		trimmedLen -= TrailingWhitespaces(input)
	}
	if len(pattern) == 0 {
		return Result{trimmedLen, trimmedLen}, nil
	}
	diff := trimmedLen - len(pattern)
	if diff < 0 {
		return Result{-1, -1}, nil
	}

	for index, r := range pattern {
		char := input.Get(index + diff)
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
func EqualMatch(input []rune, pattern []rune) (Result, *[]int) {
	lenPattern := len(pattern)
	if lenPattern == 0 {
		return Result{-1, -1}, nil
	}

	// Strip leading whitespaces
	trimmedLen := 0
	if !unicode.IsSpace(pattern[0]) {
		trimmedLen = LeadingWhitespaces(input)
	}

	// Strip trailing whitespaces
	trimmedEndLen := 0
	if !unicode.IsSpace(pattern[lenPattern-1]) {
		trimmedEndLen = TrailingWhitespaces(input)
	}

	if len(input)-trimmedLen-trimmedEndLen != lenPattern {
		return Result{-1, -1}, nil
	}
	match := true

	runesStr := string(input[trimmedLen : len(input)-trimmedEndLen])
	runesStr = strings.ToLower(runesStr)
	match = runesStr == string(pattern)

	if match {
		return Result{trimmedLen, trimmedLen + lenPattern}, nil
	}
	return Result{-1, -1}, nil
}

type Chars []rune

func (chars Chars) Get(i int) rune {
	return []rune(chars)[i]
}

func (chars Chars) Length() int {
	return len(chars)
}

func LeadingWhitespaces(chars []rune) int {
	whitespaces := 0
	for i := 0; i < len(chars); i++ {
		char := chars[i]
		if !unicode.IsSpace(char) {
			break
		}
		whitespaces++
	}
	return whitespaces
}

func TrailingWhitespaces(input []rune) int {
	whitespaces := 0
	for i := len(input) - 1; i >= 0; i-- {
		char := input[i]
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

type termType int

const (
	termFuzzy termType = iota
	termExact
	termExactBoundary
	termPrefix
	termSuffix
	termEqual
)

type term struct {
	typ  termType
	inv  bool
	text []rune
}

// String returns the string representation of a term.
func (t term) String() string {
	return fmt.Sprintf("term{typ: %d, inv: %v, text: []rune(%q)}", t.typ, t.inv, string(t.text))
}

type termSet []term

// Pattern represents search pattern
type Pattern []termSet

var _splitRegex *regexp.Regexp

func init() {
	_splitRegex = regexp.MustCompile(" +")
}

func BuildPattern(query string) Pattern {
	runes := []rune(query)
	asString := strings.TrimLeft(string(runes), " ")
	for strings.HasSuffix(asString, " ") && !strings.HasSuffix(asString, "\\ ") {
		asString = asString[:len(asString)-1]
	}

	return parseTerms(asString)
}

func parseTerms(str string) []termSet {
	str = strings.ReplaceAll(str, "\\ ", "\t")
	tokens := _splitRegex.Split(str, -1)
	var sets []termSet
	set := termSet{}
	switchSet := false
	afterBar := false
	for _, token := range tokens {
		typ, inv, text := termFuzzy, false, strings.ReplaceAll(token, "\t", " ")
		text = strings.ToLower(text)

		if len(set) > 0 && !afterBar && text == "|" {
			switchSet = false
			afterBar = true
			continue
		}
		afterBar = false

		if strings.HasPrefix(text, "!") {
			inv = true
			typ = termExact
			text = text[1:]
		}

		if text != "$" && strings.HasSuffix(text, "$") {
			typ = termSuffix
			text = text[:len(text)-1]
		}

		if len(text) > 2 && strings.HasPrefix(text, "'") && strings.HasSuffix(text, "'") {
			typ = termExactBoundary
			text = text[1 : len(text)-1]
		} else if strings.HasPrefix(text, "'") {
			// Flip exactness
			if !inv {
				typ = termExact
			} else {
				typ = termFuzzy
			}
			text = text[1:]
		} else if strings.HasPrefix(text, "^") {
			if typ == termSuffix {
				typ = termEqual
			} else {
				typ = termPrefix
			}
			text = text[1:]
		}

		if len(text) > 0 {
			if switchSet {
				sets = append(sets, set)
				set = termSet{}
			}
			textRunes := []rune(text)
			set = append(set, term{
				typ:  typ,
				inv:  inv,
				text: textRunes})
			switchSet = true
		}
	}
	if len(set) > 0 {
		sets = append(sets, set)
	}
	return sets
}

func (p Pattern) MatchItem(input string) (bool, []int) {
	var allPos []int
	inputRunes := []rune(input)
	for _, termSet := range p {
		ok, pos := termSet.match(inputRunes)
		if !ok {
			return false, nil
		}
		allPos = append(allPos, pos...)
	}

	slices.Sort(allPos)
	return true, allPos
}

func (terms termSet) match(input []rune) (bool, []int) {
	var allPos []int
	for _, term := range terms {
		var res Result
		var pos *[]int

		switch term.typ {
		case termFuzzy:
			res, pos = FuzzyMatch(input, term.text)
		case termEqual:
			res, pos = EqualMatch(input, term.text)
		case termExact:
			res, pos = ExactMatch(string(input), term.text, false)
		case termExactBoundary:
			res, pos = ExactMatch(string(input), term.text, true)
		case termPrefix:
			res, pos = PrefixMatch(input, term.text)
		case termSuffix:
			res, pos = SuffixMatch(input, term.text)
		default:
			panic("Unknown term type: " + term.String())
		}

		matched := res.Start >= 0
		if matched {
			if term.inv {
				return false, nil
			}
			if pos != nil {
				allPos = append(allPos, *pos...)
			} else {
				for idx := res.Start; idx < res.End; idx++ {
					allPos = append(allPos, idx)
				}
			}
			continue
		}

		if !term.inv {
			return false, nil
		}
	}

	return true, allPos
}
