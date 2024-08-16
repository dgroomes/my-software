// I hacked this together haphazardly from code in the Bubble Tea "Bubbles" TUI component library. I've
// stripped it down to what I want, which is close to the "fzf" user experience. I'd like to continue to refactor this
// and reconsider how I can re-use components from Bubbles. On the other hand, this does exactly what I want it to do
// and I don't need it to be extensible.
//
// See the README for much more information.

package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"github.com/charmbracelet/bubbles/cursor"
	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/paginator"
	"github.com/charmbracelet/bubbles/runeutil"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	rw "github.com/mattn/go-runewidth"
	"github.com/muesli/reflow/ansi"
	"github.com/muesli/reflow/truncate"
	"github.com/muesli/termenv"
	"github.com/rivo/uniseg"
	"github.com/sahilm/fuzzy"
	"io"
	"log"
	"os"
	"sort"
	"strings"
	"unicode"
)

var docStyle = lipgloss.NewStyle().Margin(1, 2)

func (i Item) Title() string       { return i.Value }
func (i Item) Description() string { return "" }
func (i Item) FilterValue() string { return i.Value }

type model struct {
	completedWithSelection bool
	list                   ListModel
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
		h, v := docStyle.GetFrameSize()
		SetSize(&m.list, msg.Width-h, msg.Height-v)
	}

	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

func (m model) View() string {
	return docStyle.Render(m.list.View())
}

type ItemStyles struct {
	// The Normal state.
	NormalTitle lipgloss.Style
	NormalDesc  lipgloss.Style

	// The selected item state.
	SelectedTitle lipgloss.Style
	SelectedDesc  lipgloss.Style

	// The dimmed state, for when the filter input is initially activated.
	DimmedTitle lipgloss.Style
	DimmedDesc  lipgloss.Style

	// Characters matching the current filter, if any.
	FilterMatch lipgloss.Style
}

// DefaultDelegate is a standard delegate designed to work in lists. It's
// styled by DefaultItemStyles, which can be customized as you like.
//
// The description line can be hidden by setting Description to false, which
// renders the list as single-line-items. The spacing between items can be set
// with the SetSpacing method.
type DefaultDelegate struct {
	ItemStyles ItemStyles
	spacing    int
}

func (d DefaultDelegate) Height() int {
	return 1
}

// Render prints an item.
func (s *ItemStyles) Render(w io.Writer, m ListModel, index int, item Item) {
	//log.Printf("[DefaultDelegate.Render] index=%d, item=%v\n", index, item)
	var (
		//title, desc  string
		title        string
		matchedRunes []int
	)

	title = item.Title()

	if m.width <= 0 {
		// short-circuit
		return
	}

	// Prevent text from exceeding list width
	textWidth := uint(m.width - s.NormalTitle.GetPaddingLeft() - s.NormalTitle.GetPaddingRight())
	title = truncate.StringWithTail(title, textWidth, ellipsis)

	// Conditions
	var (
		isSelected = index == m.Index()
	)

	if index < len(m.filteredItems) {
		// Get indices of matched characters
		matchedRunes = m.MatchesForItem(index)
	}

	if isSelected {
		// This is the selected item. We style it in a way that pops out.
		// Highlight matches
		unmatched := s.SelectedTitle.Inline(true)
		matched := unmatched.Inherit(s.FilterMatch)
		title = lipgloss.StyleRunes(title, matchedRunes, matched, unmatched)
		title = s.SelectedTitle.Render(title)
	} else {
		// Highlight matches
		unmatched := s.NormalTitle.Inline(true)
		matched := unmatched.Inherit(s.FilterMatch)
		title = lipgloss.StyleRunes(title, matchedRunes, matched, unmatched)
		title = s.NormalTitle.Render(title)
	}

	fmt.Fprintf(w, "%s", title)
}

var itemStyles ItemStyles

type filteredItem struct {
	item    Item  // item matched
	matches []int // rune indices of matched items
}

type filteredItems []filteredItem

func (f filteredItems) items() []Item {
	agg := make([]Item, len(f))
	for i, v := range f {
		agg[i] = v.item
	}
	return agg
}

// FilterMatchesMsg contains the items that matched the fuzzy filter. This type is designed to be used in the "Update"
// loop.
type FilterMatchesMsg []filteredItem

// Rank defines a rank for a given item.
type Rank struct {
	// The index of the item in the original input.
	Index int
	// Indices of the actual word that were matched against the filter term.
	MatchedIndexes []int
}

// Uses the "fuzzy" library (https://github.com/sahilm/fuzzy) to filter through the list.
func fuzzyFilter(term string, targets []string) []Rank {
	ranks := fuzzy.Find(term, targets)
	sort.Stable(ranks)
	result := make([]Rank, len(ranks))
	for i, r := range ranks {
		result[i] = Rank{
			Index:          r.Index,
			MatchedIndexes: r.MatchedIndexes,
		}
	}
	return result
}

// ListModel contains the state of this component.
type ListModel struct {
	itemNameSingular string
	itemNamePlural   string

	Styles            Styles
	InfiniteScrolling bool

	KeyMap      KeyMap
	width       int
	height      int
	Paginator   paginator.Model
	cursor      int
	FilterInput TextInputModel

	// The master set of items we're working with.
	items         []Item
	filteredItems filteredItems

	delegate DefaultDelegate
}

// NewList returns a new model with sensible defaults.
func NewList(items []Item, width, height int) ListModel {
	styles := DefaultStyles()

	delegate := DefaultDelegate{
		ItemStyles: itemStyles,
	}

	filterInput := NewTextInput()
	filterInput.Prompt = "Filter: "
	filterInput.PromptStyle = styles.FilterPrompt
	filterInput.Cursor.Style = styles.FilterCursor
	filterInput.CharLimit = 64
	Focus(&filterInput)

	p := paginator.New()
	p.Type = paginator.Dots
	p.ActiveDot = styles.ActivePaginationDot.String()
	p.InactiveDot = styles.InactivePaginationDot.String()

	m := ListModel{
		itemNameSingular: "Item",
		itemNamePlural:   "items",
		KeyMap:           DefaultKeyMap(),
		Styles:           styles,
		FilterInput:      filterInput,

		width:         width,
		height:        height,
		delegate:      delegate,
		items:         items,
		filteredItems: itemsAsFilterItems(items),
		Paginator:     p,
	}

	updatePagination(&m)
	return m
}

// VisibleItems returns the total items available to be shown.
func (m ListModel) VisibleItems() []Item {
	return m.filteredItems.items()
}

// SelectedItem returns the current selected item in the list.
func (m ListModel) SelectedItem() (bool, Item) {
	i := m.Index()

	items := m.VisibleItems()
	if i < 0 || len(items) == 0 || len(items) <= i {
		return false, Item{}
	}

	return true, items[i]
}

// MatchesForItem returns rune positions matched by the current filter, if any.
// Use this to style runes matched by the active filter.
//
// See DefaultItemView for a usage example.
func (m ListModel) MatchesForItem(index int) []int {
	if m.filteredItems == nil || index >= len(m.filteredItems) {
		return nil
	}
	return m.filteredItems[index].matches
}

// Index returns the index of the currently selected item as it appears in the
// entire slice of items.
func (m ListModel) Index() int {
	return m.Paginator.Page*m.Paginator.PerPage + m.cursor
}

// Cursor returns the index of the cursor on the current page.
func (m ListModel) Cursor() int {
	return m.cursor
}

func (m ListModel) Spacing() int {
	return 0
}

// CursorUp moves the cursor up. This can also move the state to the previous
// page.
func CursorUp(m *ListModel) {
	log.Printf("[CursorUp] cursor=%d\n", m.cursor)
	m.cursor--

	// If we're at the start, stop
	if m.cursor < 0 && m.Paginator.Page == 0 {
		// if infinite scrolling is enabled, go to the last item
		if m.InfiniteScrolling {
			m.Paginator.Page = m.Paginator.TotalPages - 1
			m.cursor = m.Paginator.ItemsOnPage(len(m.VisibleItems())) - 1
			return
		}

		m.cursor = 0
		return
	}

	// Move the cursor as normal
	if m.cursor >= 0 {
		return
	}

	// Go to the previous page
	m.Paginator.PrevPage()
	m.cursor = m.Paginator.ItemsOnPage(len(m.VisibleItems())) - 1
}

// CursorDown moves the cursor down. This can also advance the state to the
// next page.
func CursorDown(m *ListModel) {
	log.Printf("[CursorDown] cursor=%d\n", m.cursor)
	itemsOnPage := m.Paginator.ItemsOnPage(len(m.VisibleItems()))

	m.cursor++

	// If we're at the end, stop
	if m.cursor < itemsOnPage {
		return
	}

	// Go to the next page
	if !m.Paginator.OnLastPage() {
		log.Println("[CursorDown] Going to next page.")
		m.Paginator.NextPage()
		m.cursor = 0
		return
	}

	// During filtering the cursor position can exceed the number of
	// itemsOnPage. It's more intuitive to start the cursor at the
	// topmost position when moving it down in this scenario.
	if m.cursor > itemsOnPage {
		m.cursor = 0
		return
	}

	m.cursor = itemsOnPage - 1

	// if infinite scrolling is enabled, go to the first item
	if m.InfiniteScrolling {
		m.Paginator.Page = 0
		m.cursor = 0
	}
}

// FilterValue returns the current value of the filter.
func (m ListModel) FilterValue() string {
	return m.FilterInput.Value()
}

// SetSize sets the width and height of this component.
func SetSize(m *ListModel, width, height int) {
	setSize(m, width, height)
}

func setSize(m *ListModel, width, height int) {
	promptWidth := lipgloss.Width(m.Styles.Title.Render(m.FilterInput.Prompt))

	m.width = width
	m.height = height
	m.FilterInput.Width = width - promptWidth
	updatePagination(m)
}

func itemsAsFilterItems(items []Item) filteredItems {
	fi := make([]filteredItem, len(items))
	for i, item := range items {
		fi[i] = filteredItem{
			item: item,
		}
	}
	return fi
}

// Update pagination according to the amount of items for the current state.
func updatePagination(m *ListModel) {
	log.Println("[updatePagination]")
	index := m.Index()
	availHeight := m.height

	availHeight -= lipgloss.Height(m.titleView())
	m.Paginator.PerPage = iMax(1, availHeight/(m.delegate.Height()+m.Spacing()))

	if pages := len(m.VisibleItems()); pages < 1 {
		m.Paginator.SetTotalPages(1)
	} else {
		m.Paginator.SetTotalPages(pages)
	}

	// Restore index
	m.Paginator.Page = index / m.Paginator.PerPage
	m.cursor = index % m.Paginator.PerPage

	// Make sure the page stays in bounds
	if m.Paginator.Page >= m.Paginator.TotalPages-1 {
		m.Paginator.Page = iMax(0, m.Paginator.TotalPages-1)
	}
}

// Update is the Bubble Tea update loop.
func (m ListModel) Update(msg tea.Msg) (ListModel, tea.Cmd) {
	log.Printf("[Update] msg=%+v\n", msg)
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case FilterMatchesMsg:
		log.Println("[Update] message matched FilterMatchesMsg")
		m.filteredItems = filteredItems(msg)
		return m, nil
	}
	cmds = append(cmds, handleFiltering(&m, msg))
	cmds = append(cmds, handleBrowsing(&m, msg))

	return m, tea.Batch(cmds...)
}

// Updates for when a user is browsing the list.
func handleBrowsing(m *ListModel, msg tea.Msg) tea.Cmd {
	log.Printf("[handleBrowsing] msg type=%T value=%+v\n", msg, msg)
	var cmds []tea.Cmd
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch {
		case key.Matches(msg, m.KeyMap.CursorUp):
			log.Println("[handleBrowsing] About to call CursorUp...")
			CursorUp(m)

		case key.Matches(msg, m.KeyMap.CursorDown):
			log.Println("[handleBrowsing] About to call CursorDown...")
			CursorDown(m)

		default:
			log.Printf("[handleBrowsing] 'default' case. key=%s\n", msg.String())
		}
	}

	// Keep the index in bounds when paginating
	itemsOnPage := m.Paginator.ItemsOnPage(len(m.VisibleItems()))
	if m.cursor > itemsOnPage-1 {
		m.cursor = iMax(0, itemsOnPage-1)
	}

	log.Printf("[handleBrowsing] End of function. cursor=%d\n", m.cursor)
	return tea.Batch(cmds...)
}

// Updates for when a user is in the filter editing interface.
func handleFiltering(m *ListModel, msg tea.Msg) tea.Cmd {
	log.Printf("[handleFiltering] msg=%+v\n", msg)
	var cmds []tea.Cmd

	// Update the filter text input component
	newFilterInput, inputCmd := m.FilterInput.Update(msg)
	oldFilterInput := m.FilterInput
	filterChanged := oldFilterInput.Value() != newFilterInput.Value()
	m.FilterInput = newFilterInput
	cmds = append(cmds, inputCmd)

	// If the filtering input has changed, request updated filtering
	if filterChanged {
		log.Printf("[handleFiltering] filter changed. Was %+v, now %+v\n", oldFilterInput.Value(), newFilterInput.Value())
		cmds = append(cmds, filterItems(*m))
		m.KeyMap.AcceptWhileFiltering.SetEnabled(m.FilterInput.Value() != "")
	}

	// Update pagination
	updatePagination(m)

	return tea.Batch(cmds...)
}

// View renders the component.
func (m ListModel) View() string {
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

func (m ListModel) titleView() string {
	log.Println("[titleView]")
	var (
		view string
	)

	view += m.FilterInput.View()
	return view
}

func (m ListModel) paginationView() string {
	log.Println("[paginationView]")
	if m.Paginator.TotalPages < 2 {
		return ""
	}

	s := m.Paginator.View()

	// If the dot pagination is wider than the width of the window
	// use the arabic paginator.
	if ansi.PrintableRuneWidth(s) > m.width {
		m.Paginator.Type = paginator.Arabic
		s = m.Styles.ArabicPagination.Render(m.Paginator.View())
	}

	style := m.Styles.PaginationStyle
	if m.Spacing() == 0 && style.GetMarginTop() == 0 {
		style = style.MarginTop(1)
	}

	return style.Render(s)
}

func (m ListModel) populatedView() string {
	log.Println("[populatedView]")
	items := m.VisibleItems()

	var b strings.Builder

	// Empty states
	if len(items) == 0 {
		if true {
			return ""
		}
		return m.Styles.NoItems.Render("No " + m.itemNamePlural + ".")
	}

	if len(items) > 0 {
		start, end := m.Paginator.GetSliceBounds(len(items))
		docs := items[start:end]

		for i, item := range docs {
			(m.delegate.ItemStyles).Render(&b, m, i+start, item)
			if i != len(docs)-1 {
				fmt.Fprint(&b, strings.Repeat("\n", m.Spacing()+1))
			}
		}
	}

	// If there aren't enough items to fill up this page (always the last page)
	// then we need to add some newlines to fill up the space where items would
	// have been.
	itemsOnPage := m.Paginator.ItemsOnPage(len(items))
	if itemsOnPage < m.Paginator.PerPage {
		n := (m.Paginator.PerPage - itemsOnPage) * (m.delegate.Height() + m.Spacing())
		if len(items) == 0 {
			n -= m.delegate.Height() - 1
		}
		fmt.Fprint(&b, strings.Repeat("\n", n))
	}

	return b.String()
}

func filterItems(m ListModel) tea.Cmd {
	log.Println("[filterItems]")
	return func() tea.Msg {
		log.Println("[filterItems#func]")
		if m.FilterInput.Value() == "" {
			// When there is no input, we show all items. This is a special case where we are basically "not filtering".
			// Should this be handled earlier?
			return FilterMatchesMsg(itemsAsFilterItems(m.items))
		}

		items := m.items
		targets := make([]string, len(items))

		for i, t := range items {
			targets[i] = t.FilterValue()
		}

		var filterMatches []filteredItem
		for _, r := range fuzzyFilter(m.FilterInput.Value(), targets) {
			filterMatches = append(filterMatches, filteredItem{
				item:    items[r.Index],
				matches: r.MatchedIndexes,
			})
		}

		return FilterMatchesMsg(filterMatches)
	}
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

	itemStyles = ItemStyles{}
	itemStyles.NormalTitle = lipgloss.NewStyle().
		Foreground(lipgloss.AdaptiveColor{Light: "#1a1a1a", Dark: "#dddddd"}).
		Padding(0, 0, 0, 2)

	itemStyles.NormalDesc = itemStyles.NormalTitle.
		Foreground(lipgloss.AdaptiveColor{Light: "#A49FA5", Dark: "#777777"})

	itemStyles.SelectedTitle = lipgloss.NewStyle().
		Border(lipgloss.NormalBorder(), false, false, false, true).
		BorderForeground(lipgloss.AdaptiveColor{Light: "#F793FF", Dark: "#AD58B4"}).
		Foreground(lipgloss.AdaptiveColor{Light: "#EE6FF8", Dark: "#EE6FF8"}).
		Padding(0, 0, 0, 1)

	itemStyles.SelectedDesc = itemStyles.SelectedTitle.
		Foreground(lipgloss.AdaptiveColor{Light: "#F793FF", Dark: "#AD58B4"})

	itemStyles.DimmedTitle = lipgloss.NewStyle().
		Foreground(lipgloss.AdaptiveColor{Light: "#A49FA5", Dark: "#777777"}).
		Padding(0, 0, 0, 2)

	itemStyles.DimmedDesc = itemStyles.DimmedTitle.
		Foreground(lipgloss.AdaptiveColor{Light: "#C2B8C2", Dark: "#4D4D4D"})

	itemStyles.FilterMatch = lipgloss.NewStyle().Underline(true)
}

const (
	bullet   = "•"
	ellipsis = "…"
)

// Styles contains style definitions for this list component. By default, these
// values are generated by DefaultStyles.
type Styles struct {
	TitleBar     lipgloss.Style
	Title        lipgloss.Style
	FilterPrompt lipgloss.Style
	FilterCursor lipgloss.Style

	// Default styling for matched characters in a filter. This can be
	// overridden by delegates.
	DefaultFilterCharacterMatch lipgloss.Style

	StatusBar             lipgloss.Style
	StatusEmpty           lipgloss.Style
	StatusBarActiveFilter lipgloss.Style
	StatusBarFilterCount  lipgloss.Style

	NoItems lipgloss.Style

	PaginationStyle lipgloss.Style
	HelpStyle       lipgloss.Style

	// Styled characters.
	ActivePaginationDot   lipgloss.Style
	InactivePaginationDot lipgloss.Style
	ArabicPagination      lipgloss.Style
	DividerDot            lipgloss.Style
}

// DefaultStyles returns a set of default style definitions for this list
// component.
func DefaultStyles() (s Styles) {
	verySubduedColor := lipgloss.AdaptiveColor{Light: "#DDDADA", Dark: "#3C3C3C"}
	subduedColor := lipgloss.AdaptiveColor{Light: "#9B9B9B", Dark: "#5C5C5C"}

	s.TitleBar = lipgloss.NewStyle().Padding(0, 0, 1, 2)

	s.Title = lipgloss.NewStyle().
		Background(lipgloss.Color("62")).
		Foreground(lipgloss.Color("230")).
		Padding(0, 1)

	s.FilterPrompt = lipgloss.NewStyle().
		Foreground(lipgloss.AdaptiveColor{Light: "#04B575", Dark: "#ECFD65"})

	s.FilterCursor = lipgloss.NewStyle().
		Foreground(lipgloss.AdaptiveColor{Light: "#EE6FF8", Dark: "#EE6FF8"})

	s.DefaultFilterCharacterMatch = lipgloss.NewStyle().Underline(true)

	s.StatusBar = lipgloss.NewStyle().
		Foreground(lipgloss.AdaptiveColor{Light: "#A49FA5", Dark: "#777777"}).
		Padding(0, 0, 1, 2)

	s.StatusEmpty = lipgloss.NewStyle().Foreground(subduedColor)

	s.StatusBarActiveFilter = lipgloss.NewStyle().
		Foreground(lipgloss.AdaptiveColor{Light: "#1a1a1a", Dark: "#dddddd"})

	s.StatusBarFilterCount = lipgloss.NewStyle().Foreground(verySubduedColor)

	s.NoItems = lipgloss.NewStyle().
		Foreground(lipgloss.AdaptiveColor{Light: "#909090", Dark: "#626262"})

	s.ArabicPagination = lipgloss.NewStyle().Foreground(subduedColor)

	s.PaginationStyle = lipgloss.NewStyle().PaddingLeft(2)

	s.HelpStyle = lipgloss.NewStyle().Padding(1, 0, 0, 2)

	s.ActivePaginationDot = lipgloss.NewStyle().
		Foreground(lipgloss.AdaptiveColor{Light: "#847A85", Dark: "#979797"}).
		SetString(bullet)

	s.InactivePaginationDot = lipgloss.NewStyle().
		Foreground(verySubduedColor).
		SetString(bullet)

	s.DividerDot = lipgloss.NewStyle().
		Foreground(verySubduedColor).
		SetString(" " + bullet + " ")

	return s
}

// KeyMap defines keybindings. It satisfies to the help.KeyMap interface, which
// is used to render the menu.
type KeyMap struct {
	// Keybindings used when browsing the list.
	CursorUp   key.Binding
	CursorDown key.Binding
	Filter     key.Binding

	// Keybindings used when setting a filter.
	CancelWhileFiltering key.Binding
	AcceptWhileFiltering key.Binding
}

// DefaultKeyMap returns a default set of keybindings.
func DefaultKeyMap() KeyMap {
	return KeyMap{
		// Browsing.
		CursorUp: key.NewBinding(
			key.WithKeys("up"),
			key.WithHelp("↑", "up"),
		),
		CursorDown: key.NewBinding(
			key.WithKeys("down"),
			key.WithHelp("↓", "down"),
		),

		AcceptWhileFiltering: key.NewBinding(
			//key.WithKeys("enter", "up", "down"),
			key.WithKeys("enter"),
			key.WithHelp("enter", "apply filter"),
		),
	}
}

// TextInputKeyMap is the key bindings for different actions within the textinput.
type TextInputKeyMap struct {
	CharacterForward        key.Binding
	CharacterBackward       key.Binding
	WordForward             key.Binding
	WordBackward            key.Binding
	DeleteWordBackward      key.Binding
	DeleteWordForward       key.Binding
	DeleteAfterCursor       key.Binding
	DeleteBeforeCursor      key.Binding
	DeleteCharacterBackward key.Binding
	DeleteCharacterForward  key.Binding
	LineStart               key.Binding
	LineEnd                 key.Binding
}

// TextInputDefaultKeyMap is the default set of key bindings for navigating and acting
// upon the textinput.
var TextInputDefaultKeyMap = TextInputKeyMap{
	CharacterForward:        key.NewBinding(key.WithKeys("right", "ctrl+f")),
	CharacterBackward:       key.NewBinding(key.WithKeys("left", "ctrl+b")),
	WordForward:             key.NewBinding(key.WithKeys("alt+right", "alt+f")),
	WordBackward:            key.NewBinding(key.WithKeys("alt+left", "alt+b")),
	DeleteWordBackward:      key.NewBinding(key.WithKeys("alt+backspace", "ctrl+w")),
	DeleteWordForward:       key.NewBinding(key.WithKeys("alt+delete", "alt+d")),
	DeleteAfterCursor:       key.NewBinding(key.WithKeys("ctrl+k")),
	DeleteBeforeCursor:      key.NewBinding(key.WithKeys("ctrl+u")),
	DeleteCharacterBackward: key.NewBinding(key.WithKeys("backspace", "ctrl+h")),
	DeleteCharacterForward:  key.NewBinding(key.WithKeys("delete", "ctrl+d")),
	LineStart:               key.NewBinding(key.WithKeys("home", "ctrl+a")),
	LineEnd:                 key.NewBinding(key.WithKeys("end", "ctrl+e")),
}

// TextInputModel is the Bubble Tea model for this text input element.
type TextInputModel struct {
	Err error

	// General settings.
	Prompt      string
	Placeholder string
	Cursor      cursor.Model

	// Styles. These will be applied as inline styles.
	//
	// For an introduction to styling with Lip Gloss see:
	// https://github.com/charmbracelet/lipgloss
	PromptStyle      lipgloss.Style
	TextStyle        lipgloss.Style
	PlaceholderStyle lipgloss.Style

	// Deprecated: use Cursor.Style instead.
	CursorStyle lipgloss.Style

	// CharLimit is the maximum amount of characters this input element will
	// accept. If 0 or less, there's no limit.
	CharLimit int

	// Width is the maximum number of characters that can be displayed at once.
	// It essentially treats the text field like a horizontally scrolling
	// viewport. If 0 or less this setting is ignored.
	Width int

	// KeyMap encodes the keybindings recognized by the widget.
	KeyMap TextInputKeyMap

	// Underlying text value.
	value []rune

	// focus indicates whether user input focus should be on this input
	// component. When false, ignore keyboard input and hide the cursor.
	focus bool

	// Cursor position.
	pos int

	// Used to emulate a viewport when width is set and the content is
	// overflowing.
	offset      int
	offsetRight int

	// rune sanitizer for input.
	rsan runeutil.Sanitizer
}

// NewTextInput creates a new model with default settings.
func NewTextInput() TextInputModel {
	return TextInputModel{
		Prompt:           "> ",
		CharLimit:        0,
		PlaceholderStyle: lipgloss.NewStyle().Foreground(lipgloss.Color("240")),
		Cursor:           cursor.New(),
		KeyMap:           TextInputDefaultKeyMap,

		value: nil,
		focus: false,
		pos:   0,
	}
}

func setValueInternal(m *TextInputModel, runes []rune) {
	empty := len(m.value) == 0
	m.Err = nil

	if m.CharLimit > 0 && len(runes) > m.CharLimit {
		m.value = runes[:m.CharLimit]
	} else {
		m.value = runes
	}
	if (m.pos == 0 && empty) || m.pos > len(m.value) {
		SetCursor(m, len(m.value))
	}
	handleOverflow(m)
}

// Value returns the value of the text input.
func (m TextInputModel) Value() string {
	return string(m.value)
}

// Position returns the cursor position.
func (m TextInputModel) Position() int {
	return m.pos
}

// SetCursor moves the cursor to the given position. If the position is
// out of bounds the cursor will be moved to the start or end accordingly.
func SetCursor(m *TextInputModel, pos int) {
	m.pos = clamp(pos, 0, len(m.value))
	handleOverflow(m)
}

// CursorStart moves the cursor to the start of the input field.
func CursorStart(m *TextInputModel) {
	SetCursor(m, 0)
}

// CursorEnd moves the cursor to the end of the input field.
func CursorEnd(m *TextInputModel) {
	SetCursor(m, len(m.value))
}

// Focus sets the focus state on the model. When the model is in focus it can
// receive keyboard input and the cursor will be shown.
func Focus(m *TextInputModel) tea.Cmd {
	m.focus = true
	return m.Cursor.Focus()
}

// rsan initializes or retrieves the rune sanitizer.
func san(m *TextInputModel) runeutil.Sanitizer {
	if m.rsan == nil {
		// Textinput has all its input on a single line so collapse
		// newlines/tabs to single spaces.
		m.rsan = runeutil.NewSanitizer(
			runeutil.ReplaceTabs(" "), runeutil.ReplaceNewlines(" "))
	}
	return m.rsan
}

//goland:noinspection GoMixedReceiverTypes
func insertRunesFromUserInput(m *TextInputModel, v []rune) {
	// Clean up any special characters in the input provided by the
	// clipboard. This avoids bugs due to e.g. tab characters and
	// whatnot.
	paste := san(m).Sanitize(v)

	var availSpace int
	if m.CharLimit > 0 {
		availSpace = m.CharLimit - len(m.value)

		// If the char limit's been reached, cancel.
		if availSpace <= 0 {
			return
		}

		// If there's not enough space to paste the whole thing cut the pasted
		// runes down, so they'll fit.
		if availSpace < len(paste) {
			paste = paste[:availSpace]
		}
	}

	// Stuff before and after the cursor
	head := m.value[:m.pos]
	tailSrc := m.value[m.pos:]
	tail := make([]rune, len(tailSrc))
	copy(tail, tailSrc)

	oldPos := m.pos

	// Insert pasted runes
	for _, r := range paste {
		head = append(head, r)
		m.pos++
		if m.CharLimit > 0 {
			availSpace--
			if availSpace <= 0 {
				break
			}
		}
	}

	// Put it all back together
	value := append(head, tail...)
	setValueInternal(m, value)

	if m.Err != nil {
		m.pos = oldPos
	}
}

// If a max width is defined, perform some logic to treat the visible area
// as a horizontally scrolling viewport.
func handleOverflow(m *TextInputModel) {
	if m.Width <= 0 || uniseg.StringWidth(string(m.value)) <= m.Width {
		m.offset = 0
		m.offsetRight = len(m.value)
		return
	}

	// Correct right offset if we've deleted characters
	m.offsetRight = iMin(m.offsetRight, len(m.value))

	if m.pos < m.offset {
		m.offset = m.pos

		w := 0
		i := 0
		runes := m.value[m.offset:]

		for i < len(runes) && w <= m.Width {
			w += rw.RuneWidth(runes[i])
			if w <= m.Width+1 {
				i++
			}
		}

		m.offsetRight = m.offset + i
	} else if m.pos >= m.offsetRight {
		m.offsetRight = m.pos

		w := 0
		runes := m.value[:m.offsetRight]
		i := len(runes) - 1

		for i > 0 && w < m.Width {
			w += rw.RuneWidth(runes[i])
			if w <= m.Width {
				i--
			}
		}

		m.offset = m.offsetRight - (len(runes) - 1 - i)
	}
}

// deleteBeforeCursor deletes all text before the cursor.
func deleteBeforeCursor(m *TextInputModel) {
	m.value = m.value[m.pos:]
	m.offset = 0
	SetCursor(m, 0)
}

// deleteAfterCursor deletes all text after the cursor. If input is masked
// delete everything after the cursor so as not to reveal word breaks in the
// masked input.
func deleteAfterCursor(m *TextInputModel) {
	m.value = m.value[:m.pos]
	SetCursor(m, len(m.value))
}

// deleteWordBackward deletes the word left to the cursor.
func deleteWordBackward(m *TextInputModel) {
	if m.pos == 0 || len(m.value) == 0 {
		return
	}

	// Linter note: it's critical that we acquire the initial cursor position
	// here prior to altering it via SetCursor() below. As such, moving this
	// call into the corresponding if-clause does not apply here.
	oldPos := m.pos //nolint:ifshort

	SetCursor(m, m.pos-1)
	for unicode.IsSpace(m.value[m.pos]) {
		if m.pos <= 0 {
			break
		}
		// ignore series of whitespace before cursor
		SetCursor(m, m.pos-1)
	}

	for m.pos > 0 {
		if !unicode.IsSpace(m.value[m.pos]) {
			SetCursor(m, m.pos-1)
		} else {
			if m.pos > 0 {
				// keep the previous space
				SetCursor(m, m.pos+1)
			}
			break
		}
	}

	if oldPos > len(m.value) {
		m.value = m.value[:m.pos]
	} else {
		m.value = append(m.value[:m.pos], m.value[oldPos:]...)
	}
}

// deleteWordForward deletes the word right to the cursor. If input is masked
// delete everything after the cursor so as not to reveal word breaks in the
// masked input.
func deleteWordForward(m *TextInputModel) {
	if m.pos >= len(m.value) || len(m.value) == 0 {
		return
	}

	oldPos := m.pos
	SetCursor(m, m.pos+1)
	for unicode.IsSpace(m.value[m.pos]) {
		// ignore series of whitespace after cursor
		SetCursor(m, m.pos+1)

		if m.pos >= len(m.value) {
			break
		}
	}

	for m.pos < len(m.value) {
		if !unicode.IsSpace(m.value[m.pos]) {
			SetCursor(m, m.pos+1)
		} else {
			break
		}
	}

	if m.pos > len(m.value) {
		m.value = m.value[:oldPos]
	} else {
		m.value = append(m.value[:oldPos], m.value[m.pos:]...)
	}

	SetCursor(m, oldPos)
}

// wordBackward moves the cursor one word to the left. If input is masked, move
// input to the start so as not to reveal word breaks in the masked input.
//
//goland:noinspection GoMixedReceiverTypes
func wordBackward(m *TextInputModel) {
	if m.pos == 0 || len(m.value) == 0 {
		return
	}

	i := m.pos - 1
	for i >= 0 {
		if unicode.IsSpace(m.value[i]) {
			SetCursor(m, m.pos-1)
			i--
		} else {
			break
		}
	}

	for i >= 0 {
		if !unicode.IsSpace(m.value[i]) {
			SetCursor(m, m.pos-1)
			i--
		} else {
			break
		}
	}
}

// wordForward moves the cursor one word to the right. If the input is masked,
// move input to the end so as not to reveal word breaks in the masked input.
//
//goland:noinspection GoMixedReceiverTypes
func wordForward(m *TextInputModel) {
	if m.pos >= len(m.value) || len(m.value) == 0 {
		return
	}

	i := m.pos
	for i < len(m.value) {
		if unicode.IsSpace(m.value[i]) {
			SetCursor(m, m.pos+1)
			i++
		} else {
			break
		}
	}

	for i < len(m.value) {
		if !unicode.IsSpace(m.value[i]) {
			SetCursor(m, m.pos+1)
			i++
		} else {
			break
		}
	}
}

// Update is the Bubble Tea update loop.
//
//goland:noinspection GoMixedReceiverTypes
func (m TextInputModel) Update(msg tea.Msg) (TextInputModel, tea.Cmd) {
	log.Printf("[my-textinput#Update] msg=%v\n", msg)
	if !m.focus {
		return m, nil
	}

	// Let's remember where the position of the cursor currently is so that if
	// the cursor position changes, we can reset the blink.
	oldPos := m.pos //nolint

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch {
		case key.Matches(msg, m.KeyMap.DeleteWordBackward):
			m.Err = nil
			deleteWordBackward(&m)
		case key.Matches(msg, m.KeyMap.DeleteCharacterBackward):
			m.Err = nil
			if len(m.value) > 0 {
				m.value = append(m.value[:iMax(0, m.pos-1)], m.value[m.pos:]...)
				if m.pos > 0 {
					SetCursor(&m, m.pos-1)
				}
			}
		case key.Matches(msg, m.KeyMap.WordBackward):
			wordBackward(&m)
		case key.Matches(msg, m.KeyMap.CharacterBackward):
			if m.pos > 0 {
				SetCursor(&m, m.pos-1)
			}
		case key.Matches(msg, m.KeyMap.WordForward):
			wordForward(&m)
		case key.Matches(msg, m.KeyMap.CharacterForward):
			if m.pos < len(m.value) {
				SetCursor(&m, m.pos+1)
			}
		case key.Matches(msg, m.KeyMap.LineStart):
			CursorStart(&m)
		case key.Matches(msg, m.KeyMap.DeleteCharacterForward):
			if len(m.value) > 0 && m.pos < len(m.value) {
				m.value = append(m.value[:m.pos], m.value[m.pos+1:]...)
			}
		case key.Matches(msg, m.KeyMap.LineEnd):
			CursorEnd(&m)
		case key.Matches(msg, m.KeyMap.DeleteAfterCursor):
			deleteAfterCursor(&m)
		case key.Matches(msg, m.KeyMap.DeleteBeforeCursor):
			deleteBeforeCursor(&m)
		case key.Matches(msg, m.KeyMap.DeleteWordForward):
			deleteWordForward(&m)
		default:
			// Input one or more regular characters.
			insertRunesFromUserInput(&m, msg.Runes)
		}
	}

	var cmds []tea.Cmd
	var cmd tea.Cmd

	m.Cursor, cmd = m.Cursor.Update(msg)
	cmds = append(cmds, cmd)

	if oldPos != m.pos && m.Cursor.Mode() == cursor.CursorBlink {
		m.Cursor.Blink = false
		cmds = append(cmds, m.Cursor.BlinkCmd())
	}

	handleOverflow(&m)
	return m, tea.Batch(cmds...)
}

// View renders the textinput in its current state.
//
//goland:noinspection GoMixedReceiverTypes
func (m TextInputModel) View() string {
	// Placeholder text
	if len(m.value) == 0 && m.Placeholder != "" {
		return m.placeholderView()
	}

	styleText := m.TextStyle.Inline(true).Render

	value := m.value[m.offset:m.offsetRight]
	pos := iMax(0, m.pos-m.offset)
	v := styleText(string(value[:pos]))

	if pos < len(value) {
		char := string(value[pos])
		m.Cursor.SetChar(char)
		v += m.Cursor.View()                  // cursor and text under it
		v += styleText(string(value[pos+1:])) // text after cursor
	} else {
		m.Cursor.SetChar(" ")
		v += m.Cursor.View()
	}

	// If a iMax width and background color were set fill the empty spaces with
	// the background color.
	valWidth := uniseg.StringWidth(string(value))
	if m.Width > 0 && valWidth <= m.Width {
		padding := iMax(0, m.Width-valWidth)
		if valWidth+padding <= m.Width && pos < len(value) {
			padding++
		}
		v += styleText(strings.Repeat(" ", padding))
	}

	return m.PromptStyle.Render(m.Prompt) + v
}

// placeholderView returns the prompt and placeholder view, if any.
//
//goland:noinspection GoMixedReceiverTypes
func (m TextInputModel) placeholderView() string {
	var (
		v     string
		p     = []rune(m.Placeholder)
		style = m.PlaceholderStyle.Inline(true).Render
	)

	m.Cursor.TextStyle = m.PlaceholderStyle
	m.Cursor.SetChar(string(p[:1]))
	v += m.Cursor.View()

	// If the entire placeholder is already set and no padding is needed, finish
	if m.Width < 1 && len(p) <= 1 {
		return m.PromptStyle.Render(m.Prompt) + v
	}

	// If Width is set then size placeholder accordingly
	if m.Width > 0 {
		// available width is width - len + cursor offset of 1
		minWidth := lipgloss.Width(m.Placeholder)
		availWidth := m.Width - minWidth + 1

		// if width < len, 'subtract'(add) number to len and don't add padding
		if availWidth < 0 {
			minWidth += availWidth
			availWidth = 0
		}
		// append placeholder[len] - cursor, append padding
		v += style(string(p[1:minWidth]))
		v += style(strings.Repeat(" ", availWidth))
	} else {
		// if there is no width, the placeholder can be any length
		v += style(string(p[1:]))
	}

	return m.PromptStyle.Render(m.Prompt) + v
}

func clamp(v, low, high int) int {
	if high < low {
		low, high = high, low
	}
	return iMin(high, iMax(low, v))
}

func iMin(a, b int) int {
	if a < b {
		return a
	}
	return b
}

type Item struct {
	Index int    `json:"index"`
	Value string `json:"value"`
}

func readStandardInput() []Item {
	var items []Item
	scanner := bufio.NewScanner(os.Stdin)
	i := 0
	for scanner.Scan() {
		items = append(items, Item{Index: i, Value: scanner.Text()})
		i++
	}
	if err := scanner.Err(); err != nil {
		fmt.Fprintf(os.Stderr, "error reading standard input: %v", err)
		os.Exit(1)
	}
	return items
}

func outputJson(item Item) {
	encoder := json.NewEncoder(os.Stdout)
	err := encoder.Encode(item)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error encoding JSON output: %v\n", err)
		os.Exit(1)
	}
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

	var items []Item

	if *example {
		exampleStrings := []string{
			"20° Weather",
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
		items = make([]Item, len(exampleStrings))
		for i, s := range exampleStrings {
			items[i] = Item{Index: i, Value: s}
		}
	} else {
		items = readStandardInput()
	}

	list := NewList(items, 0, 0)

	m := model{list: list}

	// Force Bubble Tea to output to the TTY. If we don't do this, then when the program is part of a pipeline, the TUI
	// isn't rendered. This problem, explanation, and work around is well described here: https://github.com/charmbracelet/bubbletea/issues/860#issue-1983089654
	tty, err := os.OpenFile("/dev/tty", os.O_WRONLY, 0)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error opening /dev/tty:", err)
		os.Exit(2)
	}
	defer tty.Close()
	p := tea.NewProgram(m, tea.WithAltScreen(), tea.WithOutput(tty))

	finalModel, err := p.Run()
	m = finalModel.(model)

	if err != nil {
		fmt.Fprintln(os.Stderr, "Error running program:", err)
		os.Exit(2)
	}

	if !m.completedWithSelection {
		log.Println("No item selected")
		os.Exit(130)
	}

	ok, selectedItem := m.list.SelectedItem()
	if ok {
		if *jsonOut {
			outputJson(selectedItem)
		} else {
			fmt.Print(selectedItem.Value)
		}
	} else {
		// An exit code of 1 indicates that no item matched. This is the same exit code used by fzf.
		os.Exit(1)
	}
}
