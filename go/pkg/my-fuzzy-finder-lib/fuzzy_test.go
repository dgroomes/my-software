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
