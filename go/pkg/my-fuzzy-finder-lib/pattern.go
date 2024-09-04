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

type term struct {
	typ           termType
	inv           bool
	text          []rune
	caseSensitive bool
	normalize     bool
}

// String returns the string representation of a term.
func (t term) String() string {
	return fmt.Sprintf("term{typ: %d, inv: %v, text: []rune(%q), caseSensitive: %v}", t.typ, t.inv, string(t.text), t.caseSensitive)
}

type termSet []term

// Pattern represents search pattern
type Pattern struct {
	fuzzy     bool
	normalize bool
	text      []rune
	termSets  []termSet
	sortable  bool
	nth       []Range
	procFun   map[termType]algo.Algo
}

var _splitRegex *regexp.Regexp

func init() {
	_splitRegex = regexp.MustCompile(" +")
}

// BuildPattern builds Pattern object from the given arguments
func BuildPattern(patternCache map[string]*Pattern, runes []rune) *Pattern {
	asString := strings.TrimLeft(string(runes), " ")
	for strings.HasSuffix(asString, " ") && !strings.HasSuffix(asString, "\\ ") {
		asString = asString[:len(asString)-1]
	}

	// We can uniquely identify the pattern for a given string since
	// search mode and caseMode do not change while the program is running
	cached, found := patternCache[asString]
	if found {
		return cached
	}

	sortable := true
	termSets := []termSet{}

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
		sortable: sortable,
		procFun:  make(map[termType]algo.Algo)}

	ptr.procFun[termFuzzy] = algo.FuzzyMatchV2
	ptr.procFun[termEqual] = algo.EqualMatch
	ptr.procFun[termExact] = algo.ExactMatchNaive
	ptr.procFun[termExactBoundary] = algo.ExactMatchBoundary
	ptr.procFun[termPrefix] = algo.PrefixMatch
	ptr.procFun[termSuffix] = algo.SuffixMatch

	patternCache[asString] = ptr
	return ptr
}

func parseTerms(str string) []termSet {
	str = strings.ReplaceAll(str, "\\ ", "\t")
	tokens := _splitRegex.Split(str, -1)
	sets := []termSet{}
	set := termSet{}
	switchSet := false
	afterBar := false
	for _, token := range tokens {
		typ, inv, text := termFuzzy, false, strings.ReplaceAll(token, "\t", " ")
		lowerText := strings.ToLower(text)
		caseSensitive := text != lowerText
		normalizeTerm := lowerText == string(algo.NormalizeRunes([]rune(lowerText)))
		if !caseSensitive {
			text = lowerText
		}

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
			if normalizeTerm {
				textRunes = algo.NormalizeRunes(textRunes)
			}
			set = append(set, term{
				typ:           typ,
				inv:           inv,
				text:          textRunes,
				caseSensitive: caseSensitive,
				normalize:     normalizeTerm})
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
func (p *Pattern) MatchItem(item *Item, withPos bool) (*Result, []Offset, *[]int) {
	if offsets, bonus, positions := p.extendedMatch(item, withPos); len(offsets) == len(p.termSets) {
		result := buildResult(item, offsets, bonus)
		slices.Sort(*positions)
		return &result, offsets, positions
	}
	return nil, nil, nil
}

func (p *Pattern) extendedMatch(item *Item, withPos bool) ([]Offset, int, *[]int) {
	input := []Token{{text: &item.text, prefixLength: 0}}
	offsets := []Offset{}
	var totalScore int
	var allPos *[]int
	if withPos {
		allPos = &[]int{}
	}
	for _, termSet := range p.termSets {
		var offset Offset
		var currentScore int
		matched := false
		for _, term := range termSet {
			pfun := p.procFun[term.typ]
			off, score, pos := p.iter(pfun, input, term.caseSensitive, term.normalize, term.text, withPos)
			if sidx := off[0]; sidx >= 0 {
				if term.inv {
					continue
				}
				offset, currentScore = off, score
				matched = true
				if withPos {
					if pos != nil {
						//goland:noinspection GoDfaNilDereference
						*allPos = append(*allPos, *pos...)
					} else {
						for idx := off[0]; idx < off[1]; idx++ {
							//goland:noinspection GoDfaNilDereference
							*allPos = append(*allPos, int(idx))
						}
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

func (p *Pattern) iter(pfun algo.Algo, tokens []Token, caseSensitive bool, normalize bool, pattern []rune, withPos bool) (Offset, int, *[]int) {
	for _, part := range tokens {
		if res, pos := pfun(caseSensitive, normalize, part.text, pattern, withPos); res.Start >= 0 {
			sidx := int32(res.Start) + part.prefixLength
			eidx := int32(res.End) + part.prefixLength
			if pos != nil {
				for idx := range *pos {
					(*pos)[idx] += int(part.prefixLength)
				}
			}
			return Offset{sidx, eidx}, res.Score, pos
		}
	}
	return Offset{-1, -1}, 0, nil
}
