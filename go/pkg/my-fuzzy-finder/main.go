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
	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/paginator"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/muesli/reflow/ansi"
	"github.com/muesli/termenv"
	"github.com/sahilm/fuzzy"
	"io"
	"log"
	"os"
	"sort"
	"strings"
)

// The master list of items, repeated in various forms.
var allItemsAsFilteredItems []filteredItem
var allItems []Item
var allTargets []string

var keyCursorUp = key.NewBinding(
	key.WithKeys("up"),
	key.WithHelp("↑", "up"),
)
var keyCursorDown = key.NewBinding(
	key.WithKeys("down"),
	key.WithHelp("↓", "down"),
)

var keyAcceptWhileFiltering = key.NewBinding(
	key.WithKeys("enter"),
	key.WithHelp("enter", "apply filter"),
)

var styleDoc = lipgloss.NewStyle().Margin(1, 2)
var styleNormalTitle = lipgloss.NewStyle().
	Foreground(lipgloss.AdaptiveColor{Light: "#1a1a1a", Dark: "#dddddd"}).
	Padding(0, 0, 0, 2)
var styleSelectedTitle = lipgloss.NewStyle().
	Border(lipgloss.NormalBorder(), false, false, false, true).
	BorderForeground(lipgloss.AdaptiveColor{Light: "#F793FF", Dark: "#AD58B4"}).
	Foreground(lipgloss.AdaptiveColor{Light: "#EE6FF8", Dark: "#EE6FF8"}).
	Padding(0, 0, 0, 1)
var styleFilterMatch = lipgloss.NewStyle().Underline(true)
var styleFilterPrompt = lipgloss.NewStyle().
	Foreground(lipgloss.AdaptiveColor{Light: "#04B575", Dark: "#ECFD65"})
var styleFilterCursor = lipgloss.NewStyle().
	Foreground(lipgloss.AdaptiveColor{Light: "#EE6FF8", Dark: "#EE6FF8"})
var styleNoItems = lipgloss.NewStyle().
	Foreground(lipgloss.AdaptiveColor{Light: "#909090", Dark: "#626262"})
var stylePaginationStyle = lipgloss.NewStyle().PaddingLeft(2)
var styleActivePaginationDot = lipgloss.NewStyle().
	Foreground(lipgloss.AdaptiveColor{Light: "#847A85", Dark: "#979797"}).
	SetString(bullet)
var verySubduedColor = lipgloss.AdaptiveColor{Light: "#DDDADA", Dark: "#3C3C3C"}
var subduedColor = lipgloss.AdaptiveColor{Light: "#9B9B9B", Dark: "#5C5C5C"}
var styleInactivePaginationDot = lipgloss.NewStyle().
	Foreground(verySubduedColor).
	SetString(bullet)
var styleArabicPagination = lipgloss.NewStyle().Foreground(subduedColor)
var prompt = "Filter: "
var promptLength = len(prompt)

// Height of items? TODO support multi-line items.
const height = 1

type model struct {
	completedWithSelection bool
	list                   listModel
}

func (m model) Init() tea.Cmd {
	return nil
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		k := msg.String()
		switch k {
		case "ctrl+c", "esc":
			return m, tea.Quit
		case "enter":
			m.completedWithSelection = true
			return m, tea.Quit
		}
	case tea.WindowSizeMsg:
		h, v := styleDoc.GetFrameSize()
		var width = msg.Width - h
		m.list.width = width
		m.list.height = msg.Height - v
		m.list.input.Width = width - promptLength
		updatePagination(&m.list)
	}

	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case FilterMatchesMsg:
		log.Println("[Update] message matched FilterMatchesMsg")
		m.list.filteredItems = msg
		return m, nil
	}
	// Update the filter text input component
	newFilterInput, inputCmd := m.list.input.Update(msg)
	oldFilterInput := m.list.input
	filterChanged := oldFilterInput.Value() != newFilterInput.Value()
	m.list.input = newFilterInput
	cmds = append(cmds, inputCmd)

	// If the filtering input has changed, request updated filtering
	if filterChanged {
		log.Printf("[handleFiltering] filter changed. Was %+v, now %+v\n", oldFilterInput.Value(), newFilterInput.Value())
		log.Println("[filterItems]")
		cmds = append(cmds, func() tea.Msg {
			log.Println("[filterItems#func]")
			if m.list.input.Value() == "" {
				// When there is no input, we show all items. This is a special case where we are basically "not filtering".
				// Should this be handled earlier?
				return FilterMatchesMsg(allItemsAsFilteredItems)
			}

			// Use the "fuzzy" library (https://github.com/sahilm/fuzzy) to filter through the list.
			matches := fuzzy.Find(m.list.input.Value(), allTargets)
			sort.Stable(matches)

			filterMatches := Map(matches, func(match fuzzy.Match, _ int) filteredItem {
				return filteredItem{
					item:    allItems[match.Index],
					matches: match.MatchedIndexes,
				}
			})

			return FilterMatchesMsg(filterMatches)
		})
		keyAcceptWhileFiltering.SetEnabled(m.list.input.Value() != "")
	}

	updatePagination(&m.list)
	switch msg2 := msg.(type) {
	case tea.KeyMsg:
		switch {
		case key.Matches(msg2, keyCursorUp):
			log.Println("[handleBrowsing] About to call CursorUp...")
			m.list.cursor--

			// If we're at the start, stop
			if m.list.cursor < 0 && m.list.paginator.Page == 0 {
				m.list.cursor = 0
				break
			}

			// Move the cursor as normal
			if m.list.cursor >= 0 {
				break
			}

			// Go to the previous page
			m.list.paginator.PrevPage()
			m.list.cursor = m.list.paginator.ItemsOnPage(len(m.list.visibleItems())) - 1

		case key.Matches(msg2, keyCursorDown):
			log.Println("[handleBrowsing] About to call CursorDown...")
			// CursorDown moves the cursor down. This can also advance the state to the
			// next page.
			itemsOnPage := m.list.paginator.ItemsOnPage(len(m.list.visibleItems()))

			m.list.cursor++

			// If we're at the end, stop
			if m.list.cursor < itemsOnPage {
				break
			}

			// Go to the next page
			if !m.list.paginator.OnLastPage() {
				log.Println("[CursorDown] Going to next page.")
				m.list.paginator.NextPage()
				m.list.cursor = 0
				break
			}

			// During filtering the cursor position can exceed the number of
			// itemsOnPage. It's more intuitive to start the cursor at the
			// topmost position when moving it down in this scenario.
			if m.list.cursor > itemsOnPage {
				m.list.cursor = 0
				break
			}

			m.list.cursor = itemsOnPage - 1

		default:
			log.Printf("[handleBrowsing] 'default' case. key=%s\n", msg2.String())
		}
	}

	// Keep the index in bounds when paginating
	itemsOnPage := m.list.paginator.ItemsOnPage(len(m.list.visibleItems()))
	if m.list.cursor > itemsOnPage-1 {
		m.list.cursor = iMax(0, itemsOnPage-1)
	}

	return m, tea.Batch(cmds...)
}

func (m model) View() string {
	return styleDoc.Render(m.list.View())
}

type filteredItem struct {
	item    Item  // item matched
	matches []int // rune indices of matched items
}

// FilterMatchesMsg contains the items that matched the fuzzy filter. This type is designed to be used in the "Update"
// loop.
type FilterMatchesMsg []filteredItem

type listModel struct {
	width         int
	height        int
	paginator     paginator.Model
	cursor        int
	input         textinput.Model
	filteredItems []filteredItem
}

// visibleItems returns the total items available to be shown.
func (m listModel) visibleItems() []Item {
	return Map(m.filteredItems, func(fi filteredItem, _ int) Item {
		return fi.item
	})
}

// selectedIndex returns the index of the currently selected item as it appears in the
// entire slice of items.
func (m listModel) selectedIndex() int {
	return m.paginator.Page*m.paginator.PerPage + m.cursor
}

// Cursor returns the index of the cursor on the current page.
func (m listModel) Cursor() int {
	return m.cursor
}

func (m listModel) Spacing() int {
	return 0
}

// FilterValue returns the current value of the filter.
func (m listModel) FilterValue() string {
	return m.input.Value()
}

// Update pagination according to the amount of items for the current state.
func updatePagination(m *listModel) {
	log.Println("[updatePagination]")
	index := m.selectedIndex()
	availHeight := m.height

	availHeight -= lipgloss.Height(m.titleView())
	m.paginator.PerPage = iMax(1, availHeight/(height+m.Spacing()))

	if pages := len(m.visibleItems()); pages < 1 {
		m.paginator.SetTotalPages(1)
	} else {
		m.paginator.SetTotalPages(pages)
	}

	// Restore index
	m.paginator.Page = index / m.paginator.PerPage
	m.cursor = index % m.paginator.PerPage

	// Make sure the page stays in bounds
	if m.paginator.Page >= m.paginator.TotalPages-1 {
		m.paginator.Page = iMax(0, m.paginator.TotalPages-1)
	}
}

// View renders the component.
func (m listModel) View() string {
	log.Println("[View]")
	var (
		sections    []string
		availHeight = m.height
	)

	v := m.titleView()
	sections = append(sections, v)
	availHeight -= lipgloss.Height(v)

	content := lipgloss.NewStyle().Height(availHeight).Render(m.populatedView())
	sections = append(sections, content)

	return lipgloss.JoinVertical(lipgloss.Left, sections...)
}

func (m listModel) titleView() string {
	log.Println("[titleView]")
	var (
		view string
	)

	view += m.input.View()
	return view
}

func (m listModel) paginationView() string {
	log.Println("[paginationView]")
	if m.paginator.TotalPages < 2 {
		return ""
	}

	s := m.paginator.View()

	// If the dot pagination is wider than the width of the window
	// use the arabic paginator.
	if ansi.PrintableRuneWidth(s) > m.width {
		m.paginator.Type = paginator.Arabic
		s = styleArabicPagination.Render(m.paginator.View())
	}

	style := stylePaginationStyle
	if m.Spacing() == 0 && style.GetMarginTop() == 0 {
		style = style.MarginTop(1)
	}

	return style.Render(s)
}

func (m listModel) populatedView() string {
	log.Println("[populatedView]")
	items := m.visibleItems()

	var b strings.Builder

	if len(items) == 0 {
		return styleNoItems.Render("No items match.")
	}

	start, end := m.paginator.GetSliceBounds(len(items))
	docs := items[start:end]

	for i, item := range docs {
		var index = i + start
		title := item.Value

		// TODO (figure this out and also figure out how it works with multi-line items) Prevent text from exceeding list width
		//textWidth := uint(m.width - s.NormalTitle.GetPaddingLeft() - s.NormalTitle.GetPaddingRight())
		//styleTitle = truncate.StringWithTail(styleTitle, textWidth, ellipsis)

		isSelected := index == m.selectedIndex()

		var titleStyle lipgloss.Style
		if isSelected {
			titleStyle = styleSelectedTitle
		} else {
			titleStyle = styleNormalTitle
		}

		unmatched := titleStyle.Inline(true)
		matched := unmatched.Inherit(styleFilterMatch)
		title = lipgloss.StyleRunes(title, m.filteredItems[index].matches, matched, unmatched)
		title = titleStyle.Render(title)

		fmt.Fprintf(&b, "%s", title)
		if i != len(docs)-1 {
			fmt.Fprint(&b, strings.Repeat("\n", m.Spacing()+1))
		}
	}

	// If there aren't enough items to fill up this page (always the last page)
	// then we need to add some newlines to fill up the space where items would
	// have been.
	itemsOnPage := m.paginator.ItemsOnPage(len(items))
	if itemsOnPage < m.paginator.PerPage {
		n := (m.paginator.PerPage - itemsOnPage) * (height + m.Spacing())
		if len(items) == 0 {
			n -= height - 1
		}
		fmt.Fprint(&b, strings.Repeat("\n", n))
	}

	return b.String()
}

func iMax(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func init() {
	// When the program is executed in a certain way, like when it is part of piped commands on the commandline, Bubble
	// Tea (or rather, the machinery used by Bubble Tea) won't enable colors. We can force colors.
	// See this related post: https://github.com/charmbracelet/bubbletea/issues/655#issuecomment-1429006109
	lipgloss.SetColorProfile(termenv.TrueColor)

}

const (
	bullet = "•"
	//ellipsis = "…"
)

type Item struct {
	Index int    `json:"index"`
	Value string `json:"value"`
}

func main() {
	debug := flag.Bool("debug", false, "Enable debug logging to file")
	example := flag.Bool("example", false, "Run with example data")
	jsonOut := flag.Bool("json-out", false, "Output JSON")
	flag.Parse()

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
		exampleStrings := []string{
			"20° Weather\nHello", // This is my problem. Can I get multiline items? It's getting truncated...
			"Afternoon tea",
			"Bitter melon",
			"Board game nights",
			"Bonsai trees",
			"Business school",
			"Cats",
			"Coloring books",
			"Eight hours of sleep",
			"Essential oil diffuser",
			"Fidget spinner",
			"Film photography",
			"French press",
			"Gaffer's tape",
			"Hammocks",
			"Hiking trails",
			"Jigsaw puzzles",
			"Juggling balls",
			"Kombucha brewing",
			"Linux",
			"Matcha latte",
			"Milk crates",
			"Nice socks",
			"Noise-cancelling headphones",
			"Pocket knife",
			"Polaroid camera",
			"Pottery",
			"Pour over coffee",
			"Raspberry Pi's",
			"Reusable shopping bags",
			"Rock climbing gear",
			"Rubik's cube",
			"Shampoo",
			"Solar-powered charger",
			"Sourdough starter",
			"Stickers",
			"Succulent plants",
			"Sunrise alarm clock",
			"Sushi making kit",
			"Table tennis",
			"Telescope",
			"Terrycloth",
			"The vernal equinox",
			"Ukulele",
			"Vintage typewriters",
			"VR",
			"Warm light",
			"Watercolor paints",
		}
		allItems = Map(exampleStrings, func(s string, i int) Item {
			return Item{Index: i, Value: s}
		})
	} else {
		scanner := bufio.NewScanner(os.Stdin)
		i := 0
		for scanner.Scan() {
			allItems = append(allItems, Item{Index: i, Value: scanner.Text()})
			i++
		}
		if err := scanner.Err(); err != nil {
			fmt.Fprintf(os.Stderr, "error reading standard input: %v", err)
			os.Exit(1)
		}
	}

	allItemsAsFilteredItems = Map(allItems, func(item Item, i int) filteredItem {
		return filteredItem{
			item: item,
		}
	})
	allTargets = Map(allItems, func(item Item, i int) string {
		return item.Value
	})

	filterTextInput := textinput.New()
	filterTextInput.PromptStyle = styleFilterPrompt
	filterTextInput.Prompt = prompt
	filterTextInput.CharLimit = 64
	filterTextInput.Cursor = cursor.New()
	filterTextInput.Cursor.Style = styleFilterCursor
	filterTextInput.Focus()
	filterTextInput.Cursor.Focus()

	p2 := paginator.New()
	p2.Type = paginator.Dots
	p2.ActiveDot = styleActivePaginationDot.String()
	p2.InactiveDot = styleInactivePaginationDot.String()

	listM := listModel{
		input:         filterTextInput,
		width:         0,
		height:        0,
		filteredItems: allItemsAsFilteredItems,
		paginator:     p2,
	}

	// Force Bubble Tea to output to the TTY. If we don't do this, then when the program is part of a pipeline, the TUI
	// isn't rendered. This problem, explanation, and work around is well described here: https://github.com/charmbracelet/bubbletea/issues/860#issue-1983089654
	tty, err := os.OpenFile("/dev/tty", os.O_WRONLY, 0)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error opening /dev/tty:", err)
		os.Exit(2)
	}
	defer tty.Close()
	p := tea.NewProgram(model{list: listM}, tea.WithAltScreen(), tea.WithOutput(tty))

	finalModelUncast, err := p.Run()

	if err != nil {
		fmt.Fprintln(os.Stderr, "Error running program:", err)
		os.Exit(2)
	}

	finalModel := finalModelUncast.(model)
	if !finalModel.completedWithSelection {
		log.Println("No item selected")
		os.Exit(130)
	}

	selectedIdx := finalModel.list.selectedIndex()
	visibleItems := finalModel.list.visibleItems()
	if selectedIdx < 0 || len(visibleItems) == 0 || len(visibleItems) <= selectedIdx {
		// An exit code of 1 indicates that no item matched. This is the same exit code used by fzf.
		os.Exit(1)
	}

	selectedItem := visibleItems[selectedIdx]
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
