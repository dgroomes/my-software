// THIS IS A COPY from https://github.com/junegunn/fzf/tree/8af0af3400fc36651b59a7e3f9a2bedd4a51daed
// MIT LICENSE

package my_fuzzy_finder

import (
	"fmt"
	"my-software/pkg/my-fuzzy-finder-lib/util"
	"regexp"
	"slices"
	"strings"

	"my-software/pkg/my-fuzzy-finder-lib/algo"
)

// fuzzy
// 'exact
// ^prefix-exact
// suffix-exact$
// !inverse-exact
// !'inverse-fuzzy
// !^inverse-prefix-exact
// !inverse-suffix-exact$

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

	sortable := true
	var termSets []termSet

	termSets = parseTerms(asString)
	// We should not sort the result if there are only inverse search terms
	sortable = false
Loop:
	for _, termSet := range termSets {
		for _, term := range termSet {
			if !term.inv {
				sortable = true
			}
			if sortable {
				// Can't break until we see at least one non-inverse term
				break Loop
			}
		}
	}

	return termSets
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

func (p Pattern) MatchItem(item string) (bool, []int) {
	input := util.ToChars([]byte(item))
	var allPos []int
	for _, termSet := range p {
		ok, pos := termSet.match(input)
		if !ok {
			return false, nil
		}
		allPos = append(allPos, pos...)
	}

	slices.Sort(allPos)
	return true, allPos
}

func (terms termSet) match(input util.Chars) (bool, []int) {
	var allPos []int
	for _, term := range terms {
		var res algo.Result
		var pos *[]int

		switch term.typ {
		case termFuzzy:
			res, pos = algo.FuzzyMatch(input, term.text)
		case termEqual:
			res, pos = algo.EqualMatch(input, term.text)
		case termExact:
			res, pos = algo.ExactMatchNaive(input, term.text)
		case termExactBoundary:
			res, pos = algo.ExactMatchBoundary(input, term.text)
		case termPrefix:
			res, pos = algo.PrefixMatch(input, term.text)
		case termSuffix:
			res, pos = algo.SuffixMatch(input, term.text)
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
