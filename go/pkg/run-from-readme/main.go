package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/charmbracelet/bubbles/key"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/muesli/termenv"
	fz "my-software/pkg/my-fuzzy-finder-lib"
)

const (
	noMatchExitCode     = 1
	noSelectionExitCode = 130
	queryCharLimit      = 64
	preferenceFileName  = "preferences.json"
)

var (
	frameStyle = lipgloss.NewStyle().Margin(1, 2)
	plainStyle = lipgloss.NewStyle()
	accent     = lipgloss.Color("#DA5CE4")
	muted      = lipgloss.Color("245")
	promptGray = lipgloss.Color("100")

	styleTitle = lipgloss.NewStyle().Bold(true)
	styleMuted = lipgloss.NewStyle().Foreground(muted)
	styleAccent = lipgloss.NewStyle().Foreground(accent)
	styleSelected = lipgloss.NewStyle().
			Border(lipgloss.NormalBorder(), false, false, false, true).
			BorderForeground(accent).
			Padding(0, 0, 0, 1)
	styleNormal = lipgloss.NewStyle().Padding(0, 0, 0, 2)
	styleSaved  = lipgloss.NewStyle().Foreground(accent).Bold(true)
	styleHelp   = lipgloss.NewStyle().Foreground(muted)
	styleLang   = lipgloss.NewStyle().Foreground(lipgloss.Color("0"))
	stylePreview = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(muted).
			Padding(0, 1)
)

type runMode string

const (
	runModeEscaped runMode = "escaped"
	runModeAsIs    runMode = "as-is"
)

type action int

const (
	actionDefault action = iota
	actionRunAsIs
	actionRunEscaped
)

type snippet struct {
	Language string `json:"language"`
	Content  string `json:"content"`
}

func (s snippet) key() string {
	sum := sha256.Sum256([]byte(s.Language + "\x00" + s.Content))
	return hex.EncodeToString(sum[:])
}

func (s snippet) isNu() bool {
	return s.Language == "nushell"
}

func (s snippet) isShellLike() bool {
	switch s.Language {
	case "shell", "bash", "sh":
		return true
	default:
		return false
	}
}

type snippetEntry struct {
	Snippet       snippet
	RememberedAsIs bool
}

func (e snippetEntry) defaultRunMode() runMode {
	if e.Snippet.isNu() || e.RememberedAsIs {
		return runModeAsIs
	}
	return runModeEscaped
}

func (e snippetEntry) header() string {
	var b strings.Builder
	if e.RememberedAsIs {
		b.WriteString("[saved] ")
	}
	fmt.Fprintf(&b, "[%s] [default: %s", e.Snippet.Language, e.defaultRunMode())
	if e.RememberedAsIs {
		b.WriteString(", remembered")
	}
	b.WriteString("]")
	return b.String()
}

func (e snippetEntry) filterText() string {
	return e.header() + "\n" + e.Snippet.Content
}

type match struct {
	Index     int
	Positions []int
}

type selectionOutput struct {
	Index          int     `json:"index"`
	Language       string  `json:"language"`
	Content        string  `json:"content"`
	RunMode        runMode `json:"run_mode"`
	Command        string  `json:"command"`
	RememberedAsIs bool    `json:"remembered_as_is"`
}

type preferences struct {
	RunAsIs map[string]map[string]bool `json:"run_as_is"`
}

func loadPreferences() (preferences, error) {
	dir, err := preferencesDir()
	if err != nil {
		return preferences{}, err
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return preferences{}, err
	}
	path := filepath.Join(dir, preferenceFileName)
	data, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return preferences{RunAsIs: map[string]map[string]bool{}}, nil
	}
	if err != nil {
		return preferences{}, err
	}
	var prefs preferences
	if err := json.Unmarshal(data, &prefs); err != nil {
		return preferences{}, err
	}
	if prefs.RunAsIs == nil {
		prefs.RunAsIs = map[string]map[string]bool{}
	}
	return prefs, nil
}

func savePreferences(prefs preferences) error {
	dir, err := preferencesDir()
	if err != nil {
		return err
	}
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	path := filepath.Join(dir, preferenceFileName)
	data, err := json.MarshalIndent(prefs, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0o644)
}

func preferencesDir() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(home, ".run-from-readme-go"), nil
}

type keyMap struct {
	Up         key.Binding
	Down       key.Binding
	Accept     key.Binding
	RunAsIs    key.Binding
	RunEscaped key.Binding
	Cancel     key.Binding
}

func defaultKeyMap() keyMap {
	return keyMap{
		Up:         key.NewBinding(key.WithKeys("up", "ctrl+p"), key.WithHelp("up", "previous")),
		Down:       key.NewBinding(key.WithKeys("down", "ctrl+n"), key.WithHelp("down", "next")),
		Accept:     key.NewBinding(key.WithKeys("enter"), key.WithHelp("enter", "run default")),
		RunAsIs:    key.NewBinding(key.WithKeys("ctrl+o"), key.WithHelp("ctrl+o", "run as-is + save")),
		RunEscaped: key.NewBinding(key.WithKeys("ctrl+e"), key.WithHelp("ctrl+e", "run escaped once")),
		Cancel:     key.NewBinding(key.WithKeys("esc", "ctrl+c"), key.WithHelp("esc", "cancel")),
	}
}

type model struct {
	keys          keyMap
	input         textinput.Model
	readmePath    string
	entries       []snippetEntry
	filterTexts   []string
	matches       []match
	selected      int
	width         int
	height        int
	frame         lipgloss.Style
	action        *action
	completed     bool
}

func newModel(readmePath string, entries []snippetEntry, initialQuery string) model {
	input := textinput.New()
	input.Prompt = "Filter: "
	input.PromptStyle = lipgloss.NewStyle().Foreground(promptGray)
	input.Cursor.Style = lipgloss.NewStyle().Foreground(accent)
	input.CharLimit = queryCharLimit
	input.Focus()
	input.SetValue(initialQuery)
	filterTexts := make([]string, len(entries))
	for i, entry := range entries {
		filterTexts[i] = entry.filterText()
	}
	m := model{
		keys:        defaultKeyMap(),
		input:       input,
		readmePath:  readmePath,
		entries:     entries,
		filterTexts: filterTexts,
		selected:    0,
		frame:       frameStyle,
	}
	m.refreshMatches()
	return m
}

func (m model) Init() tea.Cmd {
	return textinput.Blink
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		if msg.Width <= 70 || msg.Height <= 16 {
			m.frame = plainStyle
		} else {
			m.frame = frameStyle
		}
		hz, _ := m.frame.GetFrameSize()
		m.input.Width = max(10, msg.Width-hz-lipgloss.Width(m.input.Prompt)-4)
		return m, nil
	case tea.KeyMsg:
		switch {
		case key.Matches(msg, m.keys.Cancel):
			return m, tea.Quit
		case key.Matches(msg, m.keys.Accept):
			act := actionDefault
			m.action = &act
			m.completed = true
			return m, tea.Quit
		case key.Matches(msg, m.keys.RunAsIs):
			act := actionRunAsIs
			m.action = &act
			m.completed = true
			return m, tea.Quit
		case key.Matches(msg, m.keys.RunEscaped):
			act := actionRunEscaped
			m.action = &act
			m.completed = true
			return m, tea.Quit
		case key.Matches(msg, m.keys.Up):
			if len(m.matches) > 0 && m.selected > 0 {
				m.selected--
			}
			return m, nil
		case key.Matches(msg, m.keys.Down):
			if len(m.matches) > 0 && m.selected < len(m.matches)-1 {
				m.selected++
			}
			return m, nil
		}
	}

	oldQuery := m.input.Value()
	m.input, cmd = m.input.Update(msg)
	if m.input.Value() != oldQuery {
		m.refreshMatches()
	}
	return m, cmd
}

func (m *model) refreshMatches() {
	query := m.input.Value()
	if query == "" {
		m.matches = make([]match, len(m.entries))
		for i := range m.entries {
			m.matches[i] = match{Index: i}
		}
	} else {
		m.matches = m.matches[:0]
		pattern := fz.BuildPattern(query)
		for i, text := range m.filterTexts {
			if ok, positions := pattern.MatchItem(strings.ToLower(text)); ok {
				m.matches = append(m.matches, match{Index: i, Positions: positions})
			}
		}
	}
	if len(m.matches) == 0 {
		m.selected = 0
		return
	}
	if m.selected >= len(m.matches) {
		m.selected = len(m.matches) - 1
	}
}

func (m model) View() string {
	if m.width == 0 || m.height == 0 {
		return ""
	}

	helpLine1 := lipgloss.JoinHorizontal(lipgloss.Left,
		styleAccent.Render("Enter"), " run default   ",
		styleAccent.Render("Ctrl+O"), " run as-is + save   ",
		styleAccent.Render("Ctrl+E"), " run escaped once   ",
		styleAccent.Render("Esc"), " cancel",
	)

	defaultText := "n/a"
	if entry := m.selectedEntry(); entry != nil {
		defaultText = string(entry.defaultRunMode())
	}
	helpLine2 := lipgloss.JoinHorizontal(lipgloss.Left,
		"Selected default: ",
		styleAccent.Render(defaultText),
		"   ",
		styleHelp.Render("[saved] marks snippets whose Enter default is remembered"),
	)

	body := m.renderBody()
	sections := []string{
		m.input.View(),
		helpLine1,
		helpLine2,
		body,
	}
	return m.frame.Render(lipgloss.JoinVertical(lipgloss.Left, sections...))
}

func (m model) renderBody() string {
	if len(m.matches) == 0 {
		return styleMuted.Render("No matches.")
	}

	listWidth := max(36, m.width/2)
	if m.width < 100 {
		listWidth = max(28, m.width/2-2)
	}
	previewWidth := max(24, m.width-listWidth-8)

	var rows []string
	for i, match := range m.matches {
		entry := m.entries[match.Index]
		rendered := renderEntry(entry, i == m.selected)
		if i == m.selected {
			rendered = styleSelected.Width(listWidth).Render(rendered)
		} else {
			rendered = styleNormal.Width(listWidth).Render(rendered)
		}
		rows = append(rows, rendered)
	}

	list := lipgloss.JoinVertical(lipgloss.Left, rows...)
	preview := stylePreview.Width(previewWidth).Render(m.previewText(previewWidth - 2))
	return lipgloss.JoinHorizontal(lipgloss.Top, list, "  ", preview)
}

func (m model) previewText(width int) string {
	entry := m.selectedEntry()
	if entry == nil {
		return "No selection."
	}
	lines := []string{
		styleTitle.Render("Focused snippet"),
		entry.header(),
		"",
		wordWrap(entry.Snippet.Content, max(20, width)),
	}
	return strings.Join(lines, "\n")
}

func renderEntry(entry snippetEntry, selected bool) string {
	headerStyle := styleLang
	if selected {
		headerStyle = styleAccent
	}
	header := headerStyle.Render(entry.header())
	previewLine := firstLine(entry.Snippet.Content)
	if previewLine == "" {
		previewLine = "(empty snippet)"
	}
	return header + "\n" + previewLine
}

func (m model) selectedEntry() *snippetEntry {
	if len(m.matches) == 0 || m.selected < 0 || m.selected >= len(m.matches) {
		return nil
	}
	entry := &m.entries[m.matches[m.selected].Index]
	return entry
}

type parsedArgs struct {
	readmePath  string
	jsonOut     bool
	query       string
	selectIndex int
	action      string
	help        bool
}

func parseArgs(argv []string) (parsedArgs, error) {
	args := parsedArgs{
		readmePath:  "README.md",
		selectIndex: -1,
		action:      "default",
	}

	for i := 0; i < len(argv); i++ {
		arg := argv[i]
		if !strings.HasPrefix(arg, "-") {
			if args.readmePath != "README.md" {
				return parsedArgs{}, fmt.Errorf("too many positional arguments")
			}
			args.readmePath = arg
			continue
		}

		switch arg {
		case "--json-out":
			args.jsonOut = true
		case "--help", "-h":
			args.help = true
		case "--query":
			i++
			if i >= len(argv) {
				return parsedArgs{}, fmt.Errorf("--query requires a value")
			}
			args.query = argv[i]
		case "--select-index":
			i++
			if i >= len(argv) {
				return parsedArgs{}, fmt.Errorf("--select-index requires a value")
			}
			value, err := strconv.Atoi(argv[i])
			if err != nil {
				return parsedArgs{}, fmt.Errorf("invalid --select-index value: %w", err)
			}
			args.selectIndex = value
		case "--action":
			i++
			if i >= len(argv) {
				return parsedArgs{}, fmt.Errorf("--action requires a value")
			}
			args.action = argv[i]
		default:
			return parsedArgs{}, fmt.Errorf("unknown argument: %s", arg)
		}
	}

	return args, nil
}

func main() {
	lipgloss.SetColorProfile(termenv.TrueColor)
	args, err := parseArgs(os.Args[1:])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	if args.help {
		fmt.Println("Usage: run-from-readme [README.md] [--query TEXT] [--json-out] [--select-index N] [--action default|as-is|escaped]")
		return
	}

	if err := run(args); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
}

func run(args parsedArgs) error {
	readmePath, err := filepath.Abs(args.readmePath)
	if err != nil {
		return err
	}
	markdown, err := os.ReadFile(readmePath)
	if err != nil {
		return err
	}
	snippets, err := parseShellSnippets(markdown)
	if err != nil {
		return err
	}
	if len(snippets) == 0 {
		os.Exit(noMatchExitCode)
	}

	prefs, err := loadPreferences()
	if err != nil {
		return err
	}
	entries := make([]snippetEntry, len(snippets))
	for i, s := range snippets {
		entries[i] = snippetEntry{
			Snippet:       s,
			RememberedAsIs: prefs.RunAsIs[readmePath] != nil && prefs.RunAsIs[readmePath][s.key()],
		}
	}

	if args.selectIndex >= 0 {
		return emitNonInteractive(args, readmePath, entries, prefs)
	}

	tty, err := os.OpenFile("/dev/tty", os.O_WRONLY, 0)
	if err != nil {
		return err
	}
	defer tty.Close()

	program := tea.NewProgram(newModel(readmePath, entries, args.query), tea.WithAltScreen(), tea.WithOutput(tty))
	finalModel, err := program.Run()
	if err != nil {
		return err
	}

	if finalModel == nil {
		return errors.New("bubble tea returned nil model")
	}

	m := finalModel.(model)
	if !m.completed || m.action == nil {
		os.Exit(noSelectionExitCode)
	}
	entry := m.selectedEntry()
	if entry == nil {
		os.Exit(noMatchExitCode)
	}
	output, updatedPrefs, err := resolveSelection(readmePath, m.matches[m.selected].Index, *entry, *m.action, prefs)
	if err != nil {
		return err
	}
	if err := savePreferences(updatedPrefs); err != nil {
		return err
	}
	return writeSelection(output, args.jsonOut, os.Stdout)
}

func emitNonInteractive(args parsedArgs, readmePath string, entries []snippetEntry, prefs preferences) error {
	filtered := filterEntries(entries, args.query)
	if args.selectIndex < 0 || args.selectIndex >= len(filtered) {
		return fmt.Errorf("select-index %d is out of range for %d matches", args.selectIndex, len(filtered))
	}
	act, err := parseAction(args.action)
	if err != nil {
		return err
	}
	index := filtered[args.selectIndex].Index
	output, updatedPrefs, err := resolveSelection(readmePath, index, entries[index], act, prefs)
	if err != nil {
		return err
	}
	if err := savePreferences(updatedPrefs); err != nil {
		return err
	}
	return writeSelection(output, args.jsonOut, os.Stdout)
}

func filterEntries(entries []snippetEntry, query string) []match {
	if query == "" {
		out := make([]match, len(entries))
		for i := range entries {
			out[i] = match{Index: i}
		}
		return out
	}
	pattern := fz.BuildPattern(query)
	var matches []match
	for i, entry := range entries {
		text := strings.ToLower(entry.filterText())
		if ok, positions := pattern.MatchItem(text); ok {
			matches = append(matches, match{Index: i, Positions: positions})
		}
	}
	return matches
}

func parseAction(raw string) (action, error) {
	switch raw {
	case "default":
		return actionDefault, nil
	case "as-is":
		return actionRunAsIs, nil
	case "escaped":
		return actionRunEscaped, nil
	default:
		return actionDefault, fmt.Errorf("unknown action: %s", raw)
	}
}

func resolveSelection(readmePath string, index int, entry snippetEntry, act action, prefs preferences) (selectionOutput, preferences, error) {
	mode := entry.defaultRunMode()
	switch act {
	case actionRunAsIs:
		mode = runModeAsIs
	case actionRunEscaped:
		if entry.Snippet.isNu() {
			mode = runModeAsIs
		} else {
			mode = runModeEscaped
		}
	}

	if act == actionRunAsIs && entry.Snippet.isShellLike() {
		if prefs.RunAsIs == nil {
			prefs.RunAsIs = map[string]map[string]bool{}
		}
		if prefs.RunAsIs[readmePath] == nil {
			prefs.RunAsIs[readmePath] = map[string]bool{}
		}
		prefs.RunAsIs[readmePath][entry.Snippet.key()] = true
		entry.RememberedAsIs = true
	}

	command := entry.Snippet.Content
	if mode == runModeEscaped && entry.Snippet.isShellLike() {
		command = escapeForNu(entry.Snippet.Content)
	}
	output := selectionOutput{
		Index:          index,
		Language:       entry.Snippet.Language,
		Content:        entry.Snippet.Content,
		RunMode:        mode,
		Command:        command,
		RememberedAsIs: entry.RememberedAsIs,
	}
	return output, prefs, nil
}

func writeSelection(output selectionOutput, jsonOut bool, w io.Writer) error {
	if jsonOut {
		return json.NewEncoder(w).Encode(output)
	}
	_, err := io.WriteString(w, output.Command)
	return err
}

func parseShellSnippets(markdown []byte) ([]snippet, error) {
	var snippets []snippet
	lines := strings.Split(strings.ReplaceAll(string(markdown), "\r\n", "\n"), "\n")
	inFence := false
	fenceDelimiter := ""
	language := ""
	var content []string

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if !inFence {
			if strings.HasPrefix(trimmed, "```") || strings.HasPrefix(trimmed, "~~~") {
				delimiter := trimmed[:3]
				rest := strings.TrimSpace(trimmed[3:])
				fields := strings.Fields(rest)
				lang := ""
				if len(fields) > 0 {
					lang = strings.ToLower(fields[0])
				}
				if !isShellLanguage(lang) {
					inFence = true
					fenceDelimiter = delimiter
					language = ""
					content = nil
					continue
				}
				inFence = true
				fenceDelimiter = delimiter
				language = lang
				content = nil
			}
			continue
		}

		if strings.HasPrefix(trimmed, fenceDelimiter) {
			if language != "" {
				snippets = append(snippets, snippet{
					Language: language,
					Content:  strings.Join(content, "\n"),
				})
			}
			inFence = false
			fenceDelimiter = ""
			language = ""
			content = nil
			continue
		}

		if language != "" {
			content = append(content, line)
		}
	}
	return snippets, nil
}

func isShellLanguage(lang string) bool {
	switch lang {
	case "shell", "bash", "sh", "nushell":
		return true
	default:
		return false
	}
}

func escapeForNu(content string) string {
	maxHashes := 0
	runes := []rune(content)
	for i := 0; i < len(runes); i++ {
		if runes[i] != '\'' {
			continue
		}
		hashes := 0
		for j := i + 1; j < len(runes) && runes[j] == '#'; j++ {
			hashes++
		}
		maxHashes = max(maxHashes, hashes)
	}
	repeated := strings.Repeat("#", maxHashes+1)
	return fmt.Sprintf("bash -c (r%s'\n%s\n'%s | str substring 1..-2)", repeated, content, repeated)
}

func firstLine(content string) string {
	line, _, _ := strings.Cut(content, "\n")
	return line
}

func wordWrap(input string, width int) string {
	if width <= 0 {
		return input
	}
	lines := strings.Split(input, "\n")
	var wrapped []string
	for _, line := range lines {
		if lipgloss.Width(line) <= width {
			wrapped = append(wrapped, line)
			continue
		}
		var current bytes.Buffer
		for _, word := range strings.Fields(line) {
			next := word
			if current.Len() > 0 {
				next = current.String() + " " + word
			}
			if lipgloss.Width(next) > width && current.Len() > 0 {
				wrapped = append(wrapped, current.String())
				current.Reset()
				current.WriteString(word)
			} else {
				if current.Len() > 0 {
					current.WriteByte(' ')
				}
				current.WriteString(word)
			}
		}
		if current.Len() == 0 {
			wrapped = append(wrapped, line)
		} else {
			wrapped = append(wrapped, current.String())
		}
	}
	return strings.Join(wrapped, "\n")
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func init() {
	styleSelected = styleSelected.MaxWidth(80)
	styleNormal = styleNormal.MaxWidth(80)
	stylePreview = stylePreview.MaxWidth(80)
}

