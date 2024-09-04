// See the README file for more information about the `my-fuzzy-finder` program.
//
// One principle that I'm taking with this program design is "there's no need for extensibility". In particular:
//   - The source code is one file (plus dependencies)
//   - The program uses plenty of global variables for things that are constant (style definitions, keybinding definitions, etc.)
//   - The program does not define any interfaces.
//   - There is very little abstraction of code into functions. If a bit of code is not re-used, it doesn't need to be in
//     its own function. (If I had something really complicated that could be expressed succinctly in a function signature
//     then yes I would abstract it and document the algorithm).
//
// The end result of that is there should be very little indirection and an overall shorter program.

package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"github.com/charmbracelet/bubbles/cursor"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/muesli/termenv"
	"github.com/sahilm/fuzzy"
	"io"
	"log"
	"os"
	"sort"
	"strings"
)

// NoMatchExitCode is an exit code that indicates no item matched. This is the same meaning used by fzf.
const NoMatchExitCode = 1

// NoSelectionExitCode is an exit code that indicates that the user exited without selecting an item. This is the same
// meaning used by fzf.
const NoSelectionExitCode = 130

// The master list of items
var allItems []string

var styleDoc = lipgloss.NewStyle().Margin(1, 2)
var styleNormalTitle = lipgloss.NewStyle().Foreground(lipgloss.Color("#1a1a1a"))
var styleNormalTitleBox = lipgloss.NewStyle().Padding(0, 0, 0, 2)
var styleSelectedTitle = lipgloss.NewStyle().Foreground(lipgloss.Color("#EE6FF8"))
var styleSelectedTitleBox = lipgloss.NewStyle().
	Border(lipgloss.NormalBorder(), false, false, false, true).
	BorderForeground(lipgloss.Color("#F793FF")).
	Padding(0, 0, 0, 1)
var styleFilterPrompt = lipgloss.NewStyle().
	Foreground(lipgloss.AdaptiveColor{Light: "#04B575", Dark: "#ECFD65"})
var styleFilterCursor = lipgloss.NewStyle().
	Foreground(lipgloss.AdaptiveColor{Light: "#EE6FF8", Dark: "#EE6FF8"})
var styleNoItems = lipgloss.NewStyle().
	Foreground(lipgloss.AdaptiveColor{Light: "#909090", Dark: "#626262"})
var prompt = "Filter: "
var promptLength = len(prompt)

type model struct {
	input                  textinput.Model
	cursor                 cursor.Model
	height                 int
	item                   int
	matches                []fuzzy.Match
	pages                  [][]fuzzy.Match
	page                   int
	pageItem               int
	completedWithSelection bool
}

func (m model) Init() tea.Cmd {
	return textinput.Blink
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	log.Printf("[Update] tea.Msg: %+v\n", msg)
	var cmds = make([]tea.Cmd, 1)
	oldInput := m.input.Value()
	m.input, cmds[0] = m.input.Update(msg)

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		hz, v := styleDoc.GetFrameSize()
		log.Printf("WindowSizeMsg: %+v Frame size: hz=%d, v=%d\n", msg, hz, v)
		m.height = msg.Height - v
		m.input.Width = msg.Width - hz - promptLength
		return pageReflow(m), tea.Batch(cmds...)
	case tea.KeyMsg:
		k := msg.String()
		switch k {
		case "ctrl+c", "esc":
			cmds = append(cmds, tea.Quit)
			return m, tea.Batch(cmds...)
		case "enter":
			m.completedWithSelection = true
			cmds = append(cmds, tea.Quit)
			return m, tea.Batch(cmds...)
		case "up":
			log.Println("Handling key press 'up'...")
			if m.item == -1 {
				log.Println("There are no items to select. Key press 'up' is a no-op.")
				return m, tea.Batch(cmds...)
			}

			if m.pageItem == 0 {
				if m.page == 0 {
					log.Println("Already selected the first item of the first page. Key press 'up' is a no-op here.")
					return m, tea.Batch(cmds...)
				}

				log.Println("Turning to the previous page, and selecting the last item on it.")
				m.page--
				m.pageItem = len(m.pages[m.page]) - 1
			} else {
				log.Println("Selecting the previous item in the page.")
				m.pageItem--
			}

			m.item = m.pages[m.page][m.pageItem].Index
			return m, tea.Batch(cmds...)
		case "down":
			log.Println("Handling key press 'down'...")
			if m.item == -1 {
				log.Println("There are no items to select. Key press 'down' is a no-op.")
				return m, tea.Batch(cmds...)
			}

			pageSize := len(m.pages[m.page])
			if m.pageItem == pageSize-1 {
				if m.page == len(m.pages)-1 {
					log.Println("Already selected the last item of the last page. Key press 'down' is a no-op here.")
					return m, tea.Batch(cmds...)
				}

				log.Println("Turning to the next page.")
				m.page++
				m.pageItem = 0
			} else {
				log.Println("Selecting the next item in the page.")
				m.pageItem++
			}

			m.item = m.pages[m.page][m.pageItem].Index
			return m, tea.Batch(cmds...)
		default: // Assume some text was entered in the filter input.
			newInput := m.input.Value()
			if oldInput != newInput {
				log.Printf("[Update] Filter changed. Was '%+v', now '%+v'. Must re-execute fuzzy finding and re-flow the pages...\n", oldInput, newInput)
				if m.input.Value() == "" {
					log.Println("No input. Skip fuzzy matching.")
					m.matches = nil
				} else {
					// Use the "fuzzy" library (https://github.com/sahilm/fuzzy) to filter through the list.
					// This is a "dirty programming pattern" because this is a relatively slow operation, and we're
					// doing it on the UI thread. But in practice, it's exactly what I want.
					matches := fuzzy.Find(m.input.Value(), allItems)
					sort.SliceStable(matches, func(i, j int) bool {
						return matches[i].Index < matches[j].Index
					})
					m.matches = matches
				}
				return pageReflow(m), tea.Batch(cmds...)
			}

			return m, tea.Batch(cmds...)
		}
	default:
		log.Printf("Unexpected message: %+v\n", msg)
		return m, tea.Batch(cmds...)
	}
}

func (m model) View() string {
	log.Println("[View]")
	var (
		sections    []string
		availHeight = m.height
	)

	v := m.input.View()
	sections = append(sections, v)
	availHeight -= lipgloss.Height(v)

	content := lipgloss.NewStyle().Height(availHeight).Render(m.populatedView())
	sections = append(sections, content)
	return styleDoc.Render(lipgloss.JoinVertical(lipgloss.Left, sections...))
}

func (m model) FilterValue() string {
	return m.input.Value()
}

// "Reflow" the selected items into a new page set. Consider that many one-line items can occupy one page whereas
// multi-line items take up more space, and thus more pages.
//
// This function also re-calculates the selected item and the page/page-item cursors.
func pageReflow(m model) model {
	var matches []fuzzy.Match
	if m.input.Value() == "" {
		log.Println("No input. Create fake matches for all items so that the pages can get created.")
		matches = Map(allItems, func(item string, i int) fuzzy.Match {
			return fuzzy.Match{Index: i}
		})
	} else {
		if len(m.matches) == 0 {
			log.Println("No matches were found. There is nothing to reflow.")
			m.item = -1
			m.pages = nil
			m.page = -1
			m.pageItem = -1
			return m
		} else {
			log.Printf("Reflowing against %d matches...\n", len(m.matches))
			log.Printf("matches: %+v\n", m.matches)
			matches = m.matches
		}
	}

	availHeight := m.height
	titleHeight := lipgloss.Height(m.input.View())
	availHeight -= titleHeight
	log.Printf("[pageReflow] titleHeight=%d availHeight=%d\n", titleHeight, availHeight)

	pages := make([][]fuzzy.Match, 0)
	page := make([]fuzzy.Match, 0)
	heightBudget := availHeight

	prevItem := m.item
	closestDistance := len(allItems)

	for _, match := range matches {
		itemHeight := lipgloss.Height(allItems[match.Index])
		if itemHeight > heightBudget {
			// We need to spill over to a new page. Complete the page we were working on.
			pages = append(pages, page)
			page = make([]fuzzy.Match, 0)
			heightBudget = availHeight // TODO handle when an item is larger than a whole page.
		}

		page = append(page, match)
		heightBudget -= itemHeight

		distance := prevItem - match.Index
		if distance < 0 {
			distance = -distance
		}

		if distance < closestDistance {
			m.item = match.Index
			m.page = len(pages)
			m.pageItem = len(page) - 1
			closestDistance = distance
		}
	}

	pages = append(pages, page)
	m.pages = pages
	return m
}

func (m model) populatedView() string {
	log.Println("[populatedView]")

	var b strings.Builder

	if len(m.pages) == 0 {
		return styleNoItems.Render("No matches.")
	}

	matches := m.pages[m.page]

	for i, match := range matches {
		item := allItems[match.Index]

		var style lipgloss.Style
		var blockStyle lipgloss.Style

		if i == m.pageItem {
			style = styleSelectedTitle
			blockStyle = styleSelectedTitleBox
		} else {
			style = styleNormalTitle
			blockStyle = styleNormalTitleBox
		}

		item = underlineMatches(item, match.MatchedIndexes, style)
		item = blockStyle.Render(item)

		if i != len(matches)-1 {
			item = item + "\n"
		}

		fmt.Fprintf(&b, "%s", item)
	}

	return b.String()
}

type Item struct {
	Index int    `json:"index"`
	Value string `json:"value"`
}

func main() {
	debug := flag.Bool("debug", false, "Enable debug logging to file")
	example := flag.Bool("example", false, "Run with example data")
	jsonIn := flag.Bool("json-in", false, "JSON array in")
	jsonOut := flag.Bool("json-out", false, "JSON out")
	flag.Parse()

	// When the program is executed in a certain way, like when it is part of piped commands on the commandline, Bubble
	// Tea (or rather, the machinery used by Bubble Tea) won't enable colors. We can force colors.
	// See this related post: https://github.com/charmbracelet/bubbletea/issues/655#issuecomment-1429006109
	lipgloss.SetColorProfile(termenv.TrueColor)

	if *debug {
		f, err := os.OpenFile("my-fuzzy-finder.log", os.O_RDWR|os.O_CREATE|os.O_APPEND, 0666)
		if err != nil {
			log.Fatalf("error opening File: %v\n", err)
		}
		defer f.Close()
		log.SetOutput(f)
	} else {
		log.SetOutput(io.Discard)
	}

	if *example {
		allItems = []string{
			"20 Weather\nHello",
			"Eight hours of sleep",
			"French press",
			"Kombucha brewing",
			"Milk crates",
			"Pour over coffee",
			"Shampoo",
			"Table tennis",
			"Terrycloth",
		}
	} else if *jsonIn {
		decoder := json.NewDecoder(os.Stdin)
		err := decoder.Decode(&allItems)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error decoding JSON input: %v", err)
			os.Exit(1)
		}
	} else {
		scanner := bufio.NewScanner(os.Stdin)
		i := 0
		for scanner.Scan() {
			allItems = append(allItems, scanner.Text())
			i++
		}
		if err := scanner.Err(); err != nil {
			fmt.Fprintf(os.Stderr, "error reading standard input: %v", err)
			os.Exit(1)
		}
	}

	if len(allItems) == 0 {
		os.Exit(NoMatchExitCode)
	}

	input := textinput.New()
	input.PromptStyle = styleFilterPrompt
	input.Prompt = prompt
	input.CharLimit = 64
	input.Cursor.Style = styleFilterCursor
	input.Focus()

	// Force Bubble Tea to output to the TTY. If we don't do this, then when the program is part of a pipeline, the TUI
	// isn't rendered. This problem, explanation, and work around is well described here: https://github.com/charmbracelet/bubbletea/issues/860#issue-1983089654
	tty, err := os.OpenFile("/dev/tty", os.O_WRONLY, 0)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error opening /dev/tty:", err)
		os.Exit(2)
	}
	defer tty.Close()

	p := tea.NewProgram(model{
		input: input,
	}, tea.WithAltScreen(), tea.WithOutput(tty))

	finalMUncast, err := p.Run()

	if err != nil {
		fmt.Fprintln(os.Stderr, "Error running program:", err)
		os.Exit(2)
	}

	if finalMUncast == nil {
		fmt.Fprintln(os.Stderr, "The final model was nil. This is unexpected.")
		os.Exit(2)
	}

	finalM := finalMUncast.(model)
	if !finalM.completedWithSelection {
		os.Exit(NoSelectionExitCode)
	}

	if finalM.item < 0 {
		os.Exit(NoMatchExitCode)
	}

	selectedItem := Item{
		Index: finalM.item,
		Value: allItems[finalM.item],
	}

	if *jsonOut {
		encoder := json.NewEncoder(os.Stdout)
		if err := encoder.Encode(selectedItem); err != nil {
			fmt.Fprintf(os.Stderr, "Error encoding JSON output: %v\n", err)
			os.Exit(1)
		}
	} else {
		fmt.Print(selectedItem.Value)
	}
}

func Map[E, T any](items []E, f func(E, int) T) []T {
	result := make([]T, len(items))
	for i, item := range items {
		result[i] = f(item, i)
	}
	return result
}

// Similar to lipgloss.StyleRunes but adapted to work for multi-line text.
func underlineMatches(str string, indices []int, style lipgloss.Style) string {
	underlineStyle := lipgloss.NewStyle().Underline(true).Inherit(style)

	// Convert slice of indices to a map for easier lookups
	m := make(map[int]struct{})
	for _, i := range indices {
		m[i] = struct{}{}
	}

	noStyle := lipgloss.NewStyle()

	var (
		out   strings.Builder
		group strings.Builder
		runes = []rune(str)
	)

	for i, r := range runes {
		if r == '\n' {
			out.WriteString(noStyle.Render("\n"))
			continue
		}

		group.WriteRune(r)

		_, matches := m[i]
		_, nextMatches := m[i+1]

		if matches != nextMatches || i == len(runes)-1 || runes[i+1] == '\n' {
			s := group.String()
			if matches {
				s = underlineStyle.Render(s)
			} else {
				s = style.Render(s)
			}
			out.WriteString(s)
			group.Reset()
		}
	}

	return out.String()
}
