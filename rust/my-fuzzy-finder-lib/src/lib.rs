use std::fmt;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Pattern(Vec<Vec<Term>>);

#[derive(Clone, Debug, PartialEq, Eq)]
enum TermType {
    Fuzzy,
    Contains,
    Word,
    Prefix,
    Suffix,
    Same,
}

#[derive(Clone, Debug, PartialEq, Eq)]
struct Term {
    typ: TermType,
    inv: bool,
    text: String,
}

impl fmt::Display for Term {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "term{{typ: {:?}, inv: {}, text: {:?}}}",
            self.typ, self.inv, self.text
        )
    }
}

pub fn build_pattern(query: &str) -> Pattern {
    let query = query.to_lowercase();
    let mut trimmed = query.trim_start_matches(' ').to_string();
    while trimmed.ends_with(' ') && !trimmed.ends_with("\\ ") {
        trimmed.pop();
    }
    Pattern(parse_terms(&trimmed))
}

pub fn matches(query: &str, item: &str) -> Option<Vec<usize>> {
    build_pattern(query).match_item(item)
}

pub fn fuzzy_match(input: &[char], pattern: &[char]) -> Option<Vec<usize>> {
    let mut found = Vec::new();
    let mut pattern_index = 0usize;
    let mut index = 0usize;

    while pattern_index < pattern.len() && index < input.len() {
        if input[index] == pattern[pattern_index] {
            found.push(index);
            pattern_index += 1;
        }
        index += 1;
    }

    if pattern_index == pattern.len() {
        Some(found)
    } else {
        None
    }
}

fn word_match(input: &[char], pattern: &[char]) -> Option<Vec<usize>> {
    let start = find_subslice(input, pattern)?;
    let end = start + pattern.len();

    if (start > 0 && !is_delimiter(input[start])) || (end < input.len() && !is_delimiter(input[end]))
    {
        return None;
    }

    Some(offsets_to_positions(start, end))
}

fn is_delimiter(ch: char) -> bool {
    matches!(ch, '/' | ',' | ':' | ';' | '|') || ch.is_whitespace()
}

impl Pattern {
    pub fn match_item(&self, input: &str) -> Option<Vec<usize>> {
        let chars: Vec<char> = input.to_lowercase().chars().collect();
        let mut all_positions = Vec::new();

        for term_set in &self.0 {
            let positions = match_term_set(term_set, &chars)?;
            all_positions.extend(positions);
        }

        all_positions.sort_unstable();
        Some(all_positions)
    }
}

fn split_tokens(query: &str) -> Vec<String> {
    let mut tokens = Vec::new();
    let mut current = String::new();

    for ch in query.chars() {
        if ch == ' ' {
            if !current.is_empty() {
                tokens.push(std::mem::take(&mut current));
            }
        } else {
            current.push(ch);
        }
    }

    if !current.is_empty() {
        tokens.push(current);
    }

    tokens
}

fn parse_terms(query: &str) -> Vec<Vec<Term>> {
    let query = query.replace("\\ ", "\t");
    let tokens = split_tokens(&query);

    let mut term_sets: Vec<Vec<Term>> = Vec::new();
    let mut term_set: Vec<Term> = Vec::new();
    let mut switch_set = false;
    let mut after_bar = false;

    for token in tokens {
        let mut typ = TermType::Fuzzy;
        let mut inv = false;
        let mut text = token.replace('\t', " ");

        if !term_set.is_empty() && !after_bar && text == "|" {
            switch_set = false;
            after_bar = true;
            continue;
        }
        after_bar = false;

        if let Some(rest) = text.strip_prefix('!') {
            inv = true;
            typ = TermType::Contains;
            text = rest.to_string();
        }

        if text != "$" && text.ends_with('$') {
            typ = TermType::Suffix;
            text.pop();
        }

        if text.len() > 2 && text.starts_with('\'') && text.ends_with('\'') {
            typ = TermType::Word;
            text = text[1..text.len() - 1].to_string();
        } else if let Some(rest) = text.strip_prefix('\'') {
            typ = if inv {
                TermType::Fuzzy
            } else {
                TermType::Contains
            };
            text = rest.to_string();
        } else if let Some(rest) = text.strip_prefix('^') {
            typ = if matches!(typ, TermType::Suffix) {
                TermType::Same
            } else {
                TermType::Prefix
            };
            text = rest.to_string();
        }

        if !text.is_empty() {
            if switch_set {
                term_sets.push(std::mem::take(&mut term_set));
            }

            term_set.push(Term { typ, inv, text });
            switch_set = true;
        }
    }

    if !term_set.is_empty() {
        term_sets.push(term_set);
    }

    term_sets
}

fn match_term_set(term_set: &[Term], input: &[char]) -> Option<Vec<usize>> {
    let mut all_positions = Vec::new();
    let mut set_matched = false;

    for term in term_set {
        let term_chars: Vec<char> = term.text.chars().collect();
        let matched_positions = match term.typ {
            TermType::Fuzzy => fuzzy_match(input, &term_chars),
            TermType::Same => {
                if input == term_chars.as_slice() {
                    Some(offsets_to_positions(0, input.len()))
                } else {
                    None
                }
            }
            TermType::Contains => find_subslice(input, &term_chars)
                .map(|start| offsets_to_positions(start, start + term_chars.len())),
            TermType::Word => word_match(input, &term_chars),
            TermType::Prefix => {
                if input.starts_with(&term_chars) {
                    Some(offsets_to_positions(0, term_chars.len()))
                } else {
                    None
                }
            }
            TermType::Suffix => {
                if input.ends_with(&term_chars) {
                    let start = input.len() - term_chars.len();
                    Some(offsets_to_positions(start, input.len()))
                } else {
                    None
                }
            }
        };

        let matched = matched_positions.is_some();
        if (matched && !term.inv) || (!matched && term.inv) {
            set_matched = true;
            if let Some(positions) = matched_positions {
                all_positions.extend(positions);
            }
            break;
        }
    }

    if set_matched {
        Some(all_positions)
    } else {
        None
    }
}

fn find_subslice(haystack: &[char], needle: &[char]) -> Option<usize> {
    if needle.is_empty() {
        return Some(0);
    }

    haystack.windows(needle.len()).position(|window| window == needle)
}

fn offsets_to_positions(start: usize, end: usize) -> Vec<usize> {
    (start..end).collect()
}

#[cfg(test)]
mod tests {
    use super::matches;

    #[test]
    fn test_match_one() {
        let tests = [
            ("Simply the same", "abc", "abc", true, Some(vec![0, 1, 2])),
            ("Simply different", "xyz", "abc", false, None),
            (
                "Unicode characters",
                "📚",
                "Learning 📚 is fun",
                true,
                Some(vec![9]),
            ),
            ("Fuzzy match", "abc", "a b_c", true, Some(vec![0, 2, 4])),
            ("Case does not matter in items", "abc", "AbC", true, Some(vec![0, 1, 2])),
            ("Case does not matter in query", "aBc", "abc", true, Some(vec![0, 1, 2])),
            ("Empty query", "", "abc", true, Some(vec![])),
            ("Empty item", "abc", "", false, None),
            ("All empty", "", "", true, Some(vec![])),
            ("Query longer than item", "abcdef", "abc", false, None),
            ("Exact match with leading quote", "'abc", "abcd", true, Some(vec![0, 1, 2])),
            ("Exact match with quotes", "'abc'", "abc", true, Some(vec![0, 1, 2])),
            ("Exact match with quotes (no match)", "'abc'", "abcd", false, None),
            (
                "Exact match with quotes and delimiter chars",
                "'abc'",
                "abc|xyz",
                true,
                Some(vec![0, 1, 2]),
            ),
            ("Prefix match", "^ab", "abc", true, Some(vec![0, 1])),
            ("Prefix match (no match)", "^bc", "abc", false, None),
            ("Suffix match", "bc$", "abc", true, Some(vec![1, 2])),
            ("Suffix match (no match)", "ab$", "abc", false, None),
            ("Full same", "^abc$", "abc", true, Some(vec![0, 1, 2])),
            ("Inverse match", "!abc", "def", true, Some(vec![])),
            ("Inverse match (no match)", "!abc", "abc", false, None),
            (
                "Multiple terms",
                "ld$ o l l e h",
                "hello world",
                true,
                Some(vec![0, 1, 2, 2, 4, 9, 10]),
            ),
            (
                "OR operator",
                "ello ^a | ^h",
                "hello",
                true,
                Some(vec![0, 1, 2, 3, 4]),
            ),
            ("Multiple ORs", "a | b c | d", "ad", true, Some(vec![0, 1])),
        ];

        for (name, query, item, expected_match, expected_positions) in tests {
            let matched = matches(query, item);
            assert_eq!(matched.is_some(), expected_match, "{name}");
            assert_eq!(matched, expected_positions, "{name}");
        }
    }
}
