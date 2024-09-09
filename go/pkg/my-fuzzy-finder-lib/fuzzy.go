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

func Match(query string, item string) (bool, []int) {
	pattern := BuildPattern(query)
	if ok, positions := pattern.MatchItem(item); ok {
		return true, positions
	}

	return false, nil
}

var delimiterChars = "/,:;|"

func FuzzyMatch(input []rune, pattern []rune) (bool, []int) {
	var found []int

	pIdx := 0
	idx := 0
	for pIdx < len(pattern) && idx < len(input) {
		r := input[idx]
		pr := pattern[pIdx]
		if r == pr {
			found = append(found, idx)
			pIdx++
		}
		idx++
	}

	if pIdx != len(pattern) {
		return false, nil
	}

	return true, found
}

func ExactMatch(input string, pattern []rune, checkBoundary bool) (bool, []int) {
	if len(pattern) == 0 {
		return true, nil
	}

	patternStr := string(pattern)

	for i := 0; i < len(input); i++ {
		if strings.HasPrefix(input[i:], patternStr) {
			if !checkBoundary || (isWordBoundary(input, i) && isWordBoundary(input, i+len(pattern))) {
				end := i + len(pattern)
				positions := offsetsToPositions(i, end)
				return true, positions
			}
		}
	}

	return false, nil
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
func PrefixMatch(input []rune, pattern []rune) (bool, []int) {
	if len(pattern) == 0 {
		return true, nil
	}

	trimmedLen := 0
	if !unicode.IsSpace(pattern[0]) {
		trimmedLen = LeadingWhitespaces(input)
	}

	if len(input)-trimmedLen < len(pattern) {
		return false, nil
	}

	for index, expected := range pattern {
		found := input[trimmedLen+index]
		if found != expected {
			return false, nil
		}
	}
	lenPattern := len(pattern)
	positions := offsetsToPositions(trimmedLen, trimmedLen+lenPattern)
	return true, positions
}

// SuffixMatch performs suffix-match
func SuffixMatch(input []rune, pattern []rune) (bool, []int) {
	lenRunes := len(input)
	trimmedLen := lenRunes
	if len(pattern) == 0 || !unicode.IsSpace(pattern[len(pattern)-1]) {
		trimmedLen -= TrailingWhitespaces(input)
	}
	diff := trimmedLen - len(pattern)
	if diff < 0 {
		return false, nil
	}

	for index, expected := range pattern {
		actual := input[index+diff]
		if actual != expected {
			return false, nil
		}
	}
	lenPattern := len(pattern)
	sidx := trimmedLen - lenPattern
	eidx := trimmedLen
	positions := offsetsToPositions(sidx, eidx)
	return true, positions
}

// EqualMatch performs equal-match
func EqualMatch(input []rune, pattern []rune) (bool, []int) {
	lenPattern := len(pattern)
	if lenPattern == 0 {
		return false, nil
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
		return false, nil
	}
	match := true

	runesStr := string(input[trimmedLen : len(input)-trimmedEndLen])
	match = runesStr == string(pattern)

	if match {
		positions := offsetsToPositions(trimmedLen, trimmedLen+lenPattern)
		return true, positions
	}
	return false, nil
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
	text string
}

// String returns the string representation of a term.
func (t term) String() string {
	return fmt.Sprintf("term{typ: %d, inv: %v, text: []rune(%q)}", t.typ, t.inv, t.text)
}

// Pattern represents search pattern
type Pattern [][]term

var _splitRegex *regexp.Regexp

func init() {
	_splitRegex = regexp.MustCompile(" +")
}

func BuildPattern(query string) Pattern {
	query = strings.ToLower(query)
	runes := []rune(query)
	asString := strings.TrimLeft(string(runes), " ")
	for strings.HasSuffix(asString, " ") && !strings.HasSuffix(asString, "\\ ") {
		asString = asString[:len(asString)-1]
	}

	return parseTerms(asString)
}

// Parse term sets from the query
//
// For example, given the query:
//
// >	aaa 'bbb ^ccc ddd$ !eee !'fff !^ggg !hhh$ | ^iii$ ^xxx | 'yyy | zzz$ | !ZZZ
//
// The parsed term sets would be:
//
// >    - Set 1:
// >        - Term 1: Fuzzy match "aaa"
// >    - Set 2:
// >        - Term 1: Match "bbb"
// >    - Set 3:
// >        - Term 1: Prefix match "ccc"
// >    - Set 4:
// >        - Term 1: Suffix match "ddd"
// >    - Set 5:
// >        - Term 1: Inverted match "eee"
// >    - Set 6:
// >        - Term 1: Inverted fuzzy match "fff"
// >    - Set 7:
// >        - Term 1: Inverted prefix match "ggg"
// >    - Set 8:
// >        - Term 1: Inverted suffix match "hhh"
// >        - Term 2: Equal (?) match "iii" (I still struggle with this one)
// >    - Set 9:
// >        - Term 1: Prefix match "xxx"
// >        - Term 2: Match "yyy"
// >        - Term 3: Suffix match "zzz"
// >        - Term 4: Inverted match "ZZZ"
func parseTerms(query string) [][]term {
	query = strings.ReplaceAll(query, "\\ ", "\t")
	tokens := _splitRegex.Split(query, -1)
	var termSets [][]term
	var termSet []term
	switchSet := false
	afterBar := false
	for _, token := range tokens {
		typ, inv, text := termFuzzy, false, strings.ReplaceAll(token, "\t", " ")

		if len(termSet) > 0 && !afterBar && text == "|" {
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
				termSets = append(termSets, termSet)
				termSet = []term{}
			}
			termSet = append(termSet, term{
				typ:  typ,
				inv:  inv,
				text: text})
			switchSet = true
		}
	}
	if len(termSet) > 0 {
		termSets = append(termSets, termSet)
	}
	return termSets
}

func (p Pattern) MatchItem(input string) (bool, []int) {
	input = strings.ToLower(input)
	var allPos []int
	for _, termSet := range p {
		ok, pos := match(termSet, input)
		if !ok {
			return false, nil
		}
		allPos = append(allPos, pos...)
	}

	slices.Sort(allPos)
	return true, allPos
}

func match(termSet []term, input string) (bool, []int) {
	var allPos []int
	setMatched := false
	for _, term := range termSet {
		var matched bool
		var pos []int

		switch term.typ {
		case termFuzzy:
			matched, pos = FuzzyMatch([]rune(input), []rune(term.text))
		case termEqual:
			matched, pos = EqualMatch([]rune(input), []rune(term.text))
		case termExact:
			matched, pos = ExactMatch(input, []rune(term.text), false)
		case termExactBoundary:
			matched, pos = ExactMatch(input, []rune(term.text), true)
		case termPrefix:
			matched, pos = PrefixMatch([]rune(input), []rune(term.text))
		case termSuffix:
			matched, pos = SuffixMatch([]rune(input), []rune(term.text))
		default:
			panic("Unknown term type: " + term.String())
		}

		if (matched && !term.inv) || (!matched && term.inv) {
			setMatched = true
			allPos = append(allPos, pos...)
			break
		}
	}

	return setMatched, allPos
}

func offsetsToPositions(start, end int) []int {
	length := end - start
	positions := make([]int, length)
	for i := 0; i < length; i++ {
		positions[i-0] = start + i
	}
	return positions
}
