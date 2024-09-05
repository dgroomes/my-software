// THIS IS A COPY from https://github.com/junegunn/fzf/tree/8af0af3400fc36651b59a7e3f9a2bedd4a51daed
// MIT LICENSE

package my_fuzzy_finder

import (
	"fmt"
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

var termsToAlgo = map[termType]algo.Algo{
	termFuzzy:         algo.FuzzyMatch,
	termEqual:         algo.EqualMatch,
	termExact:         algo.ExactMatchNaive,
	termExactBoundary: algo.ExactMatchBoundary,
	termPrefix:        algo.PrefixMatch,
	termSuffix:        algo.SuffixMatch,
}

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
type Pattern struct {
	fuzzy    bool
	text     []rune
	termSets []termSet
	sortable bool
	nth      []Range
}

var _splitRegex *regexp.Regexp

func init() {
	_splitRegex = regexp.MustCompile(" +")
}

// BuildPattern builds Pattern object from the given arguments
func BuildPattern(query string) *Pattern {
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

	ptr := &Pattern{
		fuzzy:    true,
		text:     []rune(asString),
		termSets: termSets,
		sortable: sortable}

	return ptr
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

// IsEmpty returns true if the pattern is effectively empty
func (p *Pattern) IsEmpty() bool {
	return len(p.termSets) == 0
}

// AsString returns the search query in string type
func (p *Pattern) AsString() string {
	return string(p.text)
}

// MatchItem returns true if the Item is a match
func (p *Pattern) MatchItem(item *Item) (*Result, []Offset, *[]int) {
	if offsets, bonus, positions := p.extendedMatch(item); len(offsets) == len(p.termSets) {
		result := buildResult(item, offsets, bonus)
		slices.Sort(*positions)
		return &result, offsets, positions
	}
	return nil, nil, nil
}

func (p *Pattern) extendedMatch(item *Item) ([]Offset, int, *[]int) {
	input := []Token{{text: &item.text, prefixLength: 0}}
	var offsets []Offset
	var totalScore int
	var allPos *[]int
	allPos = &[]int{}
	for _, termSet := range p.termSets {
		var offset Offset
		var currentScore int
		matched := false
		for _, term := range termSet {
			pfun := termsToAlgo[term.typ]
			off, pos := p.iter(pfun, input, term.text)
			if sidx := off[0]; sidx >= 0 {
				if term.inv {
					continue
				}
				offset = off
				matched = true
				if pos != nil {
					//goland:noinspection GoDfaNilDereference
					*allPos = append(*allPos, *pos...)
				} else {
					for idx := off[0]; idx < off[1]; idx++ {
						//goland:noinspection GoDfaNilDereference
						*allPos = append(*allPos, int(idx))
					}
				}
				break
			} else if term.inv {
				offset, currentScore = Offset{0, 0}, 0
				matched = true
				continue
			}
		}
		if matched {
			offsets = append(offsets, offset)
			totalScore += currentScore
		}
	}
	return offsets, totalScore, allPos
}

func (p *Pattern) iter(pfun algo.Algo, tokens []Token, pattern []rune) (Offset, *[]int) {
	for _, part := range tokens {
		if res, pos := pfun(part.text, pattern); res.Start >= 0 {
			sidx := int32(res.Start) + part.prefixLength
			eidx := int32(res.End) + part.prefixLength
			if pos != nil {
				for idx := range *pos {
					(*pos)[idx] += int(part.prefixLength)
				}
			}
			return Offset{sidx, eidx}, pos
		}
	}
	return Offset{-1, -1}, nil
}
