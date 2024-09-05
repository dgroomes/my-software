package my_fuzzy_finder

import (
	"my-software/pkg/my-fuzzy-finder-lib/util"
)

type Match struct {
	Index     int
	Positions []int
}

func MatchOne(query string, item string) (bool, []int) {
	pattern := BuildPattern(query)
	chars := util.ToChars([]byte(item))
	_, _, positions := pattern.MatchItem(&Item{text: chars})
	if positions == nil {
		return false, nil
	}

	return true, *positions
}

func MatchAll(query string, items []string) []Match {
	pattern := BuildPattern(query)
	matches := make([]Match, 0, len(items))

	for i, item := range items {
		chars := util.ToChars([]byte(item))
		result, _, positions := pattern.MatchItem(&Item{text: chars})
		if result != nil {
			matches = append(matches, Match{
				Index:     i,
				Positions: *positions,
			})
		}
	}
	return matches
}
