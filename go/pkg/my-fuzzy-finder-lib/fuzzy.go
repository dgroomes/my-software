package my_fuzzy_finder

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
