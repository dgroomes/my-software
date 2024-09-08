package my_fuzzy_finder

import (
	"reflect"
	"testing"
)

func TestMatchOne(t *testing.T) {
	tests := map[string]struct {
		query         string
		item          string
		expectedMatch bool
		expectedPos   []int
	}{
		"Exact match": {
			query:         "abc",
			item:          "abc",
			expectedMatch: true,
			expectedPos:   []int{0, 1, 2},
		},
		"Non-ASCII characters": {
			query:         "📚",
			item:          "Learning 📚 is fun",
			expectedMatch: true,
			expectedPos:   []int{9},
		},
		"Fuzzy match": {
			query:         "abc",
			item:          "a_b_c",
			expectedMatch: true,
			expectedPos:   []int{0, 2, 4},
		},
		"Case does not matter in items": {
			query:         "abc",
			item:          "AbC",
			expectedMatch: true,
			expectedPos:   []int{0, 1, 2},
		},
		"Case does not matter in query": {
			query:         "aBc",
			item:          "abc",
			expectedMatch: true,
			expectedPos:   []int{0, 1, 2},
		},
		"No match": {
			query:         "xyz",
			item:          "abc",
			expectedMatch: false,
			expectedPos:   nil,
		},
		"Empty query": {
			query:         "",
			item:          "abc",
			expectedMatch: true,
			expectedPos:   nil,
		},
		"Empty item": {
			query:         "abc",
			item:          "",
			expectedMatch: false,
			expectedPos:   nil,
		},
		"Unicode characters": {
			query:         "áéí",
			item:          "áéíóú",
			expectedMatch: true,
			expectedPos:   []int{0, 1, 2},
		},
		"Query longer than item": {
			query:         "abcdef",
			item:          "abc",
			expectedMatch: false,
			expectedPos:   nil,
		},
		"Single character match": {
			query:         "a",
			item:          "abc",
			expectedMatch: true,
			expectedPos:   []int{0},
		},
		"Match at end": {
			query:         "c",
			item:          "abc",
			expectedMatch: true,
			expectedPos:   []int{2},
		},
		"Multiple occurrences": {
			query:         "aa",
			item:          "aaa",
			expectedMatch: true,
			expectedPos:   []int{0, 1},
		},
		"Exact match with quotes": {
			query:         "'abc'",
			item:          "abc",
			expectedMatch: true,
			expectedPos:   []int{0, 1, 2},
		},
		"Exact match with quotes (no match)": {
			query:         "'abc'",
			item:          "abcd",
			expectedMatch: false,
			expectedPos:   nil,
		},
		"Exact match with quotes and delimiter chars": {
			query:         "'abc'",
			item:          "abc|xyz",
			expectedMatch: true,
			expectedPos:   []int{0, 1, 2},
		},
		"Exact match with quotes and delimiter chars (no match)": {
			query:         "'abc'",
			item:          "abcd|xyz",
			expectedMatch: false,
			expectedPos:   nil,
		},
		"Prefix match": {
			query:         "^ab",
			item:          "abc",
			expectedMatch: true,
			expectedPos:   []int{0, 1},
		},
		"Prefix match (no match)": {
			query:         "^bc",
			item:          "abc",
			expectedMatch: false,
			expectedPos:   nil,
		},
		"Suffix match": {
			query:         "bc$",
			item:          "abc",
			expectedMatch: true,
			expectedPos:   []int{1, 2},
		},
		"Suffix match (no match)": {
			query:         "ab$",
			item:          "abc",
			expectedMatch: false,
			expectedPos:   nil,
		},
		"Sandwiched prefix suffix match (this is the only combination that invokes EqualMatch?)": {
			query:         "^abc$",
			item:          "abc",
			expectedMatch: true,
			expectedPos:   []int{0, 1, 2},
		},
		"Inverse match": {
			query:         "!abc",
			item:          "def",
			expectedMatch: true,
			expectedPos:   nil,
		},
		"Inverse match (no match)": {
			query:         "!abc",
			item:          "abc",
			expectedMatch: false,
			expectedPos:   nil,
		},
		"Multiple terms": {
			query:         "ld$ o l l e h",
			item:          "hello world",
			expectedMatch: true,
			expectedPos:   []int{0, 1, 2, 2, 4, 9, 10},
		},
		"OR operator": {
			query:         "ello ^a | ^h",
			item:          "hello",
			expectedMatch: true,
			expectedPos:   []int{0, 1, 2, 3, 4},
		},
		"Multiple ORs": {
			query:         "a | b c | d",
			item:          "ad",
			expectedMatch: true,
			expectedPos:   []int{0, 1},
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			matched, positions := MatchOne(tt.query, tt.item)
			if matched != tt.expectedMatch {
				t.Errorf("MatchOne() matched = %v, want %v", matched, tt.expectedMatch)
			}
			if !reflect.DeepEqual(positions, tt.expectedPos) {
				t.Errorf("MatchOne() positions = %v, want %v", positions, tt.expectedPos)
			}
		})
	}
}

func TestMatchAll(t *testing.T) {
	tests := map[string]struct {
		query           string
		items           []string
		expectedMatches []Match
	}{
		"Single exact match": {
			query: "abc",
			items: []string{"abc", "def", "ghi"},
			expectedMatches: []Match{
				{Index: 0, Positions: []int{0, 1, 2}},
			},
		},
		"No matches": {
			query:           "xyz",
			items:           []string{"abc", "def", "ghi"},
			expectedMatches: nil,
		},
	}

	for name, tt := range tests {
		t.Run(name, func(t *testing.T) {
			matches := MatchAll(tt.query, tt.items)
			if !reflect.DeepEqual(matches, tt.expectedMatches) {
				t.Errorf("MatchAll() = %v, want %v", matches, tt.expectedMatches)
			}
		})
	}
}
