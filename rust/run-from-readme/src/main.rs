use std::collections::{HashSet, hash_map::DefaultHasher};
use std::env;
use std::fmt::{self, Display};
use std::fs::{self, File, OpenOptions};
use std::hash::{Hash, Hasher};
use std::io::{self, Read};
use std::path::{Path, PathBuf};
use std::time::Duration;

use crossterm::cursor::{Hide, Show};
use crossterm::event::{
    self, Event, KeyCode, KeyEvent, KeyModifiers, KeyboardEnhancementFlags,
    PopKeyboardEnhancementFlags, PushKeyboardEnhancementFlags,
};
use crossterm::execute;
use crossterm::terminal::{
    EnterAlternateScreen, LeaveAlternateScreen, disable_raw_mode, enable_raw_mode,
};
use my_fuzzy_finder_lib as matcher;
use pulldown_cmark::{CodeBlockKind, Event as MarkdownEvent, Options, Parser, Tag, TagEnd};
use ratatui::Terminal;
use ratatui::backend::CrosstermBackend;
use ratatui::layout::{Constraint, Direction, Layout, Margin};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span, Text};
use ratatui::widgets::{Paragraph, Wrap};
use rusqlite::{Connection, params};
use serde::Serialize;
use unicode_width::UnicodeWidthChar;

const NO_MATCH_EXIT_CODE: i32 = 1;
const NO_SELECTION_EXIT_CODE: i32 = 130;
const QUERY_CHAR_LIMIT: usize = 64;
const ACCENT_COLOR: Color = Color::Rgb(0xDA, 0x5C, 0xE4);
const PROMPT: &str = "Filter: ";

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "kebab-case")]
enum RunMode {
    Escaped,
    AsIs,
}

impl Display for RunMode {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            RunMode::Escaped => write!(f, "escaped"),
            RunMode::AsIs => write!(f, "as-is"),
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum Action {
    Default,
    ForceAsIs,
    ForceEscaped,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
struct ShellSnippet {
    language: String,
    content: String,
}

impl ShellSnippet {
    fn is_nushell(&self) -> bool {
        self.language == "nushell"
    }

    fn is_shell_like(&self) -> bool {
        matches!(self.language.as_str(), "shell" | "bash" | "sh")
    }

    fn key(&self) -> String {
        let mut hasher = DefaultHasher::new();
        self.language.hash(&mut hasher);
        self.content.hash(&mut hasher);
        format!("{:016x}", hasher.finish())
    }
}

#[derive(Clone, Debug)]
struct SnippetEntry {
    snippet: ShellSnippet,
    remembered_as_is: bool,
}

impl SnippetEntry {
    fn default_run_mode(&self) -> RunMode {
        if self.snippet.is_nushell() || self.remembered_as_is {
            RunMode::AsIs
        } else {
            RunMode::Escaped
        }
    }

    fn filter_text(&self) -> String {
        format!(
            "{}[{}] [default: {}{}]\n{}",
            if self.remembered_as_is { "✓ " } else { "" },
            self.snippet.language,
            self.default_run_mode(),
            if self.remembered_as_is {
                ", remembered"
            } else {
                ""
            },
            self.snippet.content
        )
    }
}

#[derive(Clone, Debug)]
struct Match {
    index: usize,
    positions: Vec<usize>,
}

#[derive(Debug)]
struct App {
    entries: Vec<SnippetEntry>,
    filter_texts: Vec<String>,
    query: String,
    matches: Vec<Match>,
    pages: Vec<Vec<Match>>,
    item: Option<usize>,
    page: usize,
    page_item: usize,
    selection_action: Option<Action>,
    keyboard_enhancement_enabled: bool,
}

impl App {
    fn new(entries: Vec<SnippetEntry>, query: String, keyboard_enhancement_enabled: bool) -> Self {
        let filter_texts = entries.iter().map(SnippetEntry::filter_text).collect();
        Self {
            entries,
            filter_texts,
            query,
            matches: Vec::new(),
            pages: Vec::new(),
            item: None,
            page: 0,
            page_item: 0,
            selection_action: None,
            keyboard_enhancement_enabled,
        }
    }

    fn selected_entry(&self) -> Option<&SnippetEntry> {
        self.item.and_then(|index| self.entries.get(index))
    }

    fn render(&self, frame: &mut ratatui::Frame<'_>) {
        let area = if frame.area().height > 12 && frame.area().width > 70 {
            frame.area().inner(Margin {
                vertical: 1,
                horizontal: 2,
            })
        } else {
            frame.area()
        };

        if area.width == 0 || area.height == 0 {
            return;
        }

        let sections = Layout::default()
            .direction(Direction::Vertical)
            .constraints([
                Constraint::Length(1),
                Constraint::Length(2),
                Constraint::Min(1),
            ])
            .split(area);

        let cursor = Span::styled("█", Style::default().fg(ACCENT_COLOR));
        let input = Paragraph::new(Line::from(vec![
            Span::styled(PROMPT, Style::default().fg(Color::DarkGray)),
            Span::raw(self.query.clone()),
            cursor,
        ]));
        frame.render_widget(input, sections[0]);

        let selected_entry = self.selected_entry();
        let help_line_1 = Line::from(vec![
            Span::styled("Enter", Style::default().fg(ACCENT_COLOR)),
            Span::raw(": run default   "),
            Span::styled(
                if self.keyboard_enhancement_enabled {
                    "Shift+Enter"
                } else {
                    "Shift+Enter/F2"
                },
                Style::default().fg(ACCENT_COLOR),
            ),
            Span::raw(": run as-is   "),
            Span::styled("Esc", Style::default().fg(ACCENT_COLOR)),
            Span::raw(": cancel"),
        ]);
        let help_line_2 = Line::from(vec![
            Span::raw("Selected default: "),
            Span::styled(
                selected_entry
                    .map(|entry| entry.default_run_mode().to_string())
                    .unwrap_or_else(|| "n/a".to_string()),
                Style::default().fg(Color::Yellow),
            ),
            Span::raw("   [default: as-is, remembered] means Enter reuses your earlier choice"),
        ]);
        frame.render_widget(Paragraph::new(Text::from(vec![help_line_1, help_line_2])), sections[1]);

        let content = if self.pages.is_empty() {
            Text::from(Line::from(Span::styled(
                "No matches.",
                Style::default().fg(Color::DarkGray),
            )))
        } else {
            let page = &self.pages[self.page];
            let text_width = sections[2].width.saturating_sub(2).max(1);
            let mut lines = Vec::new();

            for (index, item_match) in page.iter().enumerate() {
                let selected = index == self.page_item;
                lines.extend(render_item(
                    &self.filter_texts[item_match.index],
                    &item_match.positions,
                    selected,
                    text_width,
                ));
            }

            Text::from(lines)
        };

        let content = Paragraph::new(content).wrap(Wrap { trim: false });
        frame.render_widget(content, sections[2]);
    }

    fn refresh_matches(&mut self, height: u16, width: u16) {
        if self.query.is_empty() {
            self.matches.clear();
        } else {
            self.matches = match_all(&self.query, &self.filter_texts);
        }
        self.reflow(height, width);
    }

    fn reflow(&mut self, height: u16, width: u16) {
        if self.entries.is_empty() {
            self.pages.clear();
            self.item = None;
            self.page = 0;
            self.page_item = 0;
            return;
        }

        let matches = if self.query.is_empty() {
            self.filter_texts
                .iter()
                .enumerate()
                .map(|(index, _)| Match {
                    index,
                    positions: Vec::new(),
                })
                .collect::<Vec<_>>()
        } else if self.matches.is_empty() {
            self.pages.clear();
            self.item = None;
            self.page = 0;
            self.page_item = 0;
            return;
        } else {
            self.matches.clone()
        };

        let use_margin = height > 12 && width > 70;
        let inner_height = if use_margin {
            height.saturating_sub(2)
        } else {
            height
        };
        let inner_width = if use_margin {
            width.saturating_sub(4)
        } else {
            width
        };
        let available_height = inner_height.saturating_sub(3).max(1) as usize;
        let available_width = inner_width.saturating_sub(2).max(1) as usize;

        let previous_item = self.item.unwrap_or(0);
        let mut closest_distance = self.entries.len();
        let mut pages: Vec<Vec<Match>> = Vec::new();
        let mut page: Vec<Match> = Vec::new();
        let mut height_budget = available_height;
        let mut new_selected_item = None;
        let mut new_selected_page = 0usize;
        let mut new_selected_page_item = 0usize;

        for item_match in matches {
            let item_height = wrapped_height(&self.filter_texts[item_match.index], available_width);
            if item_height > height_budget && !page.is_empty() {
                pages.push(std::mem::take(&mut page));
                height_budget = available_height;
            }

            page.push(item_match.clone());
            height_budget = height_budget.saturating_sub(item_height.max(1));

            let distance = previous_item.abs_diff(item_match.index);
            if distance < closest_distance {
                new_selected_item = Some(item_match.index);
                new_selected_page = pages.len();
                new_selected_page_item = page.len() - 1;
                closest_distance = distance;
            }
        }

        if !page.is_empty() {
            pages.push(page);
        }

        self.pages = pages;
        self.item = new_selected_item;
        self.page = new_selected_page.min(self.pages.len().saturating_sub(1));
        self.page_item = new_selected_page_item;
    }

    fn handle_key(&mut self, key: KeyEvent, height: u16, width: u16) -> bool {
        if key.kind != event::KeyEventKind::Press {
            return false;
        }

        match key.code {
            KeyCode::Char('c') if key.modifiers.contains(KeyModifiers::CONTROL) => true,
            KeyCode::Esc => true,
            KeyCode::F(2) => {
                self.selection_action = Some(Action::ForceAsIs);
                true
            }
            KeyCode::Enter => {
                self.selection_action = Some(if key.modifiers.contains(KeyModifiers::SHIFT) {
                    Action::ForceAsIs
                } else {
                    Action::Default
                });
                true
            }
            KeyCode::Up => {
                if self.item.is_none() || self.pages.is_empty() {
                    return false;
                }

                if self.page_item == 0 {
                    if self.page == 0 {
                        return false;
                    }

                    self.page -= 1;
                    self.page_item = self.pages[self.page].len() - 1;
                } else {
                    self.page_item -= 1;
                }

                self.item = Some(self.pages[self.page][self.page_item].index);
                false
            }
            KeyCode::Down => {
                if self.item.is_none() || self.pages.is_empty() {
                    return false;
                }

                if self.page_item + 1 >= self.pages[self.page].len() {
                    if self.page + 1 >= self.pages.len() {
                        return false;
                    }

                    self.page += 1;
                    self.page_item = 0;
                } else {
                    self.page_item += 1;
                }

                self.item = Some(self.pages[self.page][self.page_item].index);
                false
            }
            KeyCode::Backspace => {
                self.query.pop();
                self.refresh_matches(height, width);
                false
            }
            KeyCode::Char(ch)
                if !key.modifiers.contains(KeyModifiers::CONTROL)
                    && !key.modifiers.contains(KeyModifiers::ALT) =>
            {
                if self.query.chars().count() >= QUERY_CHAR_LIMIT {
                    return false;
                }

                self.query.push(ch);
                self.refresh_matches(height, width);
                false
            }
            _ => false,
        }
    }
}

#[derive(Debug)]
struct ParsedArgs {
    readme_path: PathBuf,
    json_out: bool,
    initial_query: String,
    select_index: Option<usize>,
    action: Option<Action>,
    show_help: bool,
}

#[derive(Serialize)]
struct SelectionOutput<'a> {
    index: usize,
    language: &'a str,
    content: &'a str,
    run_mode: RunMode,
    command: String,
    remembered_as_is: bool,
}

struct TerminalGuard {
    terminal: Terminal<CrosstermBackend<File>>,
    keyboard_enhancement_enabled: bool,
}

impl TerminalGuard {
    fn new(tty: File) -> io::Result<Self> {
        enable_raw_mode()?;
        let backend = CrosstermBackend::new(tty);
        let mut terminal = Terminal::new(backend)?;
        let keyboard_enhancement_enabled = execute!(
            terminal.backend_mut(),
            EnterAlternateScreen,
            Hide,
            PushKeyboardEnhancementFlags(KeyboardEnhancementFlags::DISAMBIGUATE_ESCAPE_CODES),
        )
        .is_ok();
        if !keyboard_enhancement_enabled {
            execute!(terminal.backend_mut(), EnterAlternateScreen, Hide)?;
        }
        terminal.clear()?;
        Ok(Self {
            terminal,
            keyboard_enhancement_enabled,
        })
    }

    fn terminal_mut(&mut self) -> &mut Terminal<CrosstermBackend<File>> {
        &mut self.terminal
    }
}

impl Drop for TerminalGuard {
    fn drop(&mut self) {
        let _ = disable_raw_mode();
        if self.keyboard_enhancement_enabled {
            let _ = execute!(
                self.terminal.backend_mut(),
                PopKeyboardEnhancementFlags,
                Show,
                LeaveAlternateScreen
            );
        } else {
            let _ = execute!(self.terminal.backend_mut(), Show, LeaveAlternateScreen);
        }
    }
}

struct PreferenceStore {
    connection: Connection,
}

impl PreferenceStore {
    fn open() -> Result<Self, Box<dyn std::error::Error>> {
        let home = env::var_os("HOME").ok_or("HOME is not set")?;
        let directory = PathBuf::from(home).join(".run-from-readme-rs");
        fs::create_dir_all(&directory)?;
        let database_path = directory.join("preferences.sqlite3");
        let connection = Connection::open(database_path)?;
        connection.execute(
            "CREATE TABLE IF NOT EXISTS snippet_preferences (
                readme_path TEXT NOT NULL,
                snippet_key TEXT NOT NULL,
                run_as_is INTEGER NOT NULL DEFAULT 1,
                PRIMARY KEY (readme_path, snippet_key)
            )",
            [],
        )?;
        Ok(Self { connection })
    }

    fn remembered_keys(
        &self,
        readme_path: &str,
    ) -> Result<HashSet<String>, Box<dyn std::error::Error>> {
        let mut statement = self.connection.prepare(
            "SELECT snippet_key
             FROM snippet_preferences
             WHERE readme_path = ?1 AND run_as_is = 1",
        )?;
        let rows = statement.query_map([readme_path], |row| row.get::<_, String>(0))?;
        let mut keys = HashSet::new();
        for row in rows {
            keys.insert(row?);
        }
        Ok(keys)
    }

    fn remember_as_is(
        &self,
        readme_path: &str,
        snippet_key: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        self.connection.execute(
            "INSERT INTO snippet_preferences (readme_path, snippet_key, run_as_is)
             VALUES (?1, ?2, 1)
             ON CONFLICT(readme_path, snippet_key)
             DO UPDATE SET run_as_is = excluded.run_as_is",
            params![readme_path, snippet_key],
        )?;
        Ok(())
    }
}

fn main() {
    match run() {
        Ok(code) => std::process::exit(code),
        Err(error) => {
            eprintln!("{error}");
            std::process::exit(2);
        }
    }
}

fn run() -> Result<i32, Box<dyn std::error::Error>> {
    let args = parse_args(env::args().skip(1).collect())?;
    if args.show_help {
        return Ok(0);
    }

    let readme_path = normalize_readme_path(&args.readme_path)?;
    let readme_path_string = readme_path.to_string_lossy().into_owned();
    let markdown = fs::read_to_string(&readme_path)?;
    let snippets = parse_shell_snippets(&markdown);
    if snippets.is_empty() {
        eprintln!("No shell snippets found in {}.", readme_path.display());
        return Ok(NO_MATCH_EXIT_CODE);
    }

    let store = PreferenceStore::open()?;
    let remembered_keys = store.remembered_keys(&readme_path_string)?;
    let entries = snippets
        .into_iter()
        .map(|snippet| {
            let remembered_as_is = remembered_keys.contains(&snippet.key());
            SnippetEntry {
                snippet,
                remembered_as_is,
            }
        })
        .collect::<Vec<_>>();

    if let Some(select_index) = args.select_index {
        return run_non_interactive(entries, select_index, &args, &store, &readme_path_string);
    }

    let tty = OpenOptions::new().read(true).write(true).open("/dev/tty")?;
    let mut terminal = TerminalGuard::new(tty.try_clone()?)?;
    let initial_area = terminal.terminal_mut().size()?;
    let mut app = App::new(
        entries,
        args.initial_query.clone(),
        terminal.keyboard_enhancement_enabled,
    );
    app.refresh_matches(initial_area.height, initial_area.width);

    loop {
        let size = terminal.terminal_mut().size()?;
        app.reflow(size.height, size.width);
        terminal.terminal_mut().draw(|frame| app.render(frame))?;

        if event::poll(Duration::from_millis(250))? {
            match event::read()? {
                Event::Key(key) => {
                    if app.handle_key(key, size.height, size.width) {
                        break;
                    }
                }
                Event::Resize(width, height) => {
                    app.reflow(height, width);
                }
                _ => {}
            }
        }
    }

    drop(terminal);

    let Some(action) = app.selection_action else {
        return Ok(NO_SELECTION_EXIT_CODE);
    };
    let Some(index) = app.item else {
        return Ok(NO_MATCH_EXIT_CODE);
    };
    let entry = app.selected_entry().expect("selected entry must exist");
    emit_selection(index, entry, action, args.json_out, &store, &readme_path_string)?;
    Ok(0)
}

fn run_non_interactive(
    entries: Vec<SnippetEntry>,
    select_index: usize,
    args: &ParsedArgs,
    store: &PreferenceStore,
    readme_path: &str,
) -> Result<i32, Box<dyn std::error::Error>> {
    let filtered_indices = filter_indices(&args.initial_query, &entries);
    let Some(entry_index) = filtered_indices.get(select_index).copied() else {
        return Err(format!(
            "select-index {} is out of range for {} matches",
            select_index,
            filtered_indices.len()
        )
        .into());
    };
    let action = args.action.unwrap_or(Action::Default);
    let entry = &entries[entry_index];
    emit_selection(entry_index, entry, action, args.json_out, store, readme_path)?;
    Ok(0)
}

fn emit_selection(
    index: usize,
    entry: &SnippetEntry,
    action: Action,
    json_out: bool,
    store: &PreferenceStore,
    readme_path: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let run_mode = resolve_run_mode(entry, action);
    let remembered_as_is = entry.remembered_as_is
        || (run_mode == RunMode::AsIs && entry.snippet.is_shell_like() && action == Action::ForceAsIs);
    if run_mode == RunMode::AsIs && entry.snippet.is_shell_like() && action == Action::ForceAsIs {
        store.remember_as_is(readme_path, &entry.snippet.key())?;
    }

    let command = build_command(&entry.snippet, run_mode);
    let selection = SelectionOutput {
        index,
        language: &entry.snippet.language,
        content: &entry.snippet.content,
        run_mode,
        command,
        remembered_as_is,
    };

    if json_out {
        serde_json::to_writer(io::stdout(), &selection)?;
        println!();
    } else {
        print!("{}", selection.command);
    }
    Ok(())
}

fn parse_args(args: Vec<String>) -> Result<ParsedArgs, Box<dyn std::error::Error>> {
    let mut parsed = ParsedArgs {
        readme_path: PathBuf::from("README.md"),
        json_out: false,
        initial_query: String::new(),
        select_index: None,
        action: None,
        show_help: false,
    };
    let mut positionals = Vec::new();
    let mut iter = args.into_iter();

    while let Some(arg) = iter.next() {
        match arg.as_str() {
            "--json-out" => parsed.json_out = true,
            "--query" => {
                parsed.initial_query = iter.next().ok_or("--query requires a value")?;
            }
            "--select-index" => {
                let value = iter.next().ok_or("--select-index requires a value")?;
                parsed.select_index = Some(value.parse()?);
            }
            "--action" => {
                let value = iter.next().ok_or("--action requires a value")?;
                parsed.action = Some(parse_action(&value)?);
            }
            "--help" | "-h" => {
                println!(
                    "Usage: run-from-readme-rs [README.md] [--json-out] [--query TEXT] [--select-index N] [--action default|as-is|escaped]"
                );
                parsed.show_help = true;
            }
            _ if arg.starts_with("--") => return Err(format!("unknown argument: {arg}").into()),
            _ => positionals.push(arg),
        }
    }

    if positionals.len() > 1 {
        return Err("too many positional arguments".into());
    }
    if let Some(path) = positionals.into_iter().next() {
        parsed.readme_path = PathBuf::from(path);
    }

    Ok(parsed)
}

fn parse_action(value: &str) -> Result<Action, Box<dyn std::error::Error>> {
    match value {
        "default" => Ok(Action::Default),
        "as-is" => Ok(Action::ForceAsIs),
        "escaped" => Ok(Action::ForceEscaped),
        _ => Err(format!("unknown action: {value}").into()),
    }
}

fn normalize_readme_path(path: &Path) -> Result<PathBuf, Box<dyn std::error::Error>> {
    if path.exists() {
        Ok(path.canonicalize()?)
    } else {
        Err(format!("README file not found: {}", path.display()).into())
    }
}

fn parse_shell_snippets(markdown: &str) -> Vec<ShellSnippet> {
    let parser = Parser::new_ext(markdown, Options::all());
    let mut snippets = Vec::new();
    let mut current_language = None;
    let mut current_content = String::new();
    let mut in_code_block = false;

    for event in parser {
        match event {
            MarkdownEvent::Start(Tag::CodeBlock(kind)) => {
                in_code_block = true;
                current_content.clear();
                current_language = match kind {
                    CodeBlockKind::Fenced(language) => {
                        let normalized = language
                            .split_whitespace()
                            .next()
                            .unwrap_or("")
                            .trim()
                            .to_ascii_lowercase();
                        if normalized.is_empty() {
                            None
                        } else {
                            Some(normalized)
                        }
                    }
                    CodeBlockKind::Indented => None,
                };
            }
            MarkdownEvent::Text(text) if in_code_block => current_content.push_str(&text),
            MarkdownEvent::SoftBreak if in_code_block => current_content.push('\n'),
            MarkdownEvent::HardBreak if in_code_block => current_content.push('\n'),
            MarkdownEvent::End(TagEnd::CodeBlock) => {
                in_code_block = false;
                remove_one_trailing_line_ending(&mut current_content);
                if let Some(language) = current_language.take() {
                    if matches!(language.as_str(), "shell" | "bash" | "sh" | "nushell") {
                        snippets.push(ShellSnippet {
                            language,
                            content: current_content.clone(),
                        });
                    }
                }
            }
            _ => {}
        }
    }

    snippets
}

fn remove_one_trailing_line_ending(content: &mut String) {
    if content.ends_with("\r\n") {
        content.truncate(content.len() - 2);
    } else if content.ends_with('\n') {
        content.pop();
    }
}

fn filter_indices(query: &str, entries: &[SnippetEntry]) -> Vec<usize> {
    if query.is_empty() {
        return (0..entries.len()).collect();
    }

    let filter_texts = entries.iter().map(SnippetEntry::filter_text).collect::<Vec<_>>();
    match_all(query, &filter_texts)
        .into_iter()
        .map(|item_match| item_match.index)
        .collect()
}

fn resolve_run_mode(entry: &SnippetEntry, action: Action) -> RunMode {
    match action {
        Action::Default => entry.default_run_mode(),
        Action::ForceAsIs => RunMode::AsIs,
        Action::ForceEscaped => {
            if entry.snippet.is_nushell() {
                RunMode::AsIs
            } else {
                RunMode::Escaped
            }
        }
    }
}

fn build_command(snippet: &ShellSnippet, run_mode: RunMode) -> String {
    if run_mode == RunMode::AsIs || snippet.is_nushell() {
        return snippet.content.clone();
    }

    let max_hash_count = max_hash_count_after_apostrophe(&snippet.content);
    let repetitive_hashtags = "#".repeat(max_hash_count + 1);
    format!(
        "bash -c (r{hashtags}'\n{content}\n'{hashtags} | str substring 1..-2)",
        hashtags = repetitive_hashtags,
        content = snippet.content
    )
}

fn max_hash_count_after_apostrophe(content: &str) -> usize {
    let chars = content.chars().collect::<Vec<_>>();
    let mut max_hash_count = 0usize;
    let mut index = 0usize;

    while index < chars.len() {
        if chars[index] == '\'' {
            let mut hash_count = 0usize;
            let mut cursor = index + 1;
            while cursor < chars.len() && chars[cursor] == '#' {
                hash_count += 1;
                cursor += 1;
            }
            max_hash_count = max_hash_count.max(hash_count);
        }
        index += 1;
    }

    max_hash_count
}

fn match_all(query: &str, items: &[String]) -> Vec<Match> {
    items
        .iter()
        .enumerate()
        .filter_map(|(index, item)| {
            matcher::matches(query, item).map(|positions| Match { index, positions })
        })
        .collect()
}

fn render_item(
    item: &str,
    matched_positions: &[usize],
    selected: bool,
    width: u16,
) -> Vec<Line<'static>> {
    let mut lines = Vec::new();
    let matched_positions = matched_positions.iter().copied().collect::<HashSet<_>>();
    let base_style = if selected {
        Style::default().fg(ACCENT_COLOR)
    } else {
        Style::default()
    };
    let prefix = if selected { "│ " } else { "  " };
    let prefix_style = if selected {
        Style::default().fg(ACCENT_COLOR)
    } else {
        Style::default()
    };

    let mut current_line = vec![Span::styled(prefix.to_string(), prefix_style)];
    let mut current_group = String::new();
    let mut current_style = base_style;

    for (index, ch) in item.chars().enumerate() {
        if ch == '\n' {
            flush_group(&mut current_line, &mut current_group, current_style);
            lines.push(Line::from(current_line));
            current_line = vec![Span::styled(prefix.to_string(), prefix_style)];
            current_style = base_style;
            continue;
        }

        let matched = matched_positions.contains(&index);
        let style = if matched {
            base_style.add_modifier(Modifier::UNDERLINED)
        } else {
            base_style
        };

        if style != current_style && !current_group.is_empty() {
            flush_group(&mut current_line, &mut current_group, current_style);
        }

        current_style = style;
        current_group.push(ch);
    }

    flush_group(&mut current_line, &mut current_group, current_style);
    lines.push(Line::from(current_line));

    let max_width = width.max(1) as usize;
    let mut wrapped = Vec::new();
    for line in lines {
        wrapped.extend(wrap_line(line, max_width));
    }
    wrapped
}

fn flush_group(line: &mut Vec<Span<'static>>, group: &mut String, style: Style) {
    if !group.is_empty() {
        line.push(Span::styled(std::mem::take(group), style));
    }
}

fn wrap_line(line: Line<'static>, width: usize) -> Vec<Line<'static>> {
    if width == 0 {
        return vec![line];
    }

    let mut result = Vec::new();
    let spans = line.spans;
    let mut current = Vec::new();
    let mut current_width = 0usize;

    for span in spans {
        let content = span.content.to_string();
        let style = span.style;
        let mut piece = String::new();

        for ch in content.chars() {
            let ch_width = UnicodeWidthChar::width(ch).unwrap_or(0).max(1);
            if current_width + ch_width > width && !piece.is_empty() {
                current.push(Span::styled(std::mem::take(&mut piece), style));
                result.push(Line::from(std::mem::take(&mut current)));
                current_width = 0;
            }

            piece.push(ch);
            current_width += ch_width;
        }

        if !piece.is_empty() {
            current.push(Span::styled(piece, style));
        }
    }

    if current.is_empty() {
        result.push(Line::default());
    } else {
        result.push(Line::from(current));
    }

    result
}

fn wrapped_height(item: &str, width: usize) -> usize {
    let width = width.max(1);
    item.split('\n')
        .map(|line| {
            let display_width = line
                .chars()
                .map(|ch| UnicodeWidthChar::width(ch).unwrap_or(0))
                .sum::<usize>();
            display_width.max(1).div_ceil(width)
        })
        .sum::<usize>()
        .max(1)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_shell_snippets_from_markdown() {
        let markdown = r#"
# demo

```bash
echo bash
```

```python
print("ignored")
```

```nushell
ls
```
"#;

        let snippets = parse_shell_snippets(markdown);
        assert_eq!(snippets.len(), 2);
        assert_eq!(snippets[0].language, "bash");
        assert_eq!(snippets[0].content, "echo bash");
        assert_eq!(snippets[1].language, "nushell");
        assert_eq!(snippets[1].content, "ls");
    }

    #[test]
    fn escapes_shell_content_for_nushell_bash_invocation() {
        let snippet = ShellSnippet {
            language: "bash".to_string(),
            content: "printf \"hello\"\nr###'unsafe'###".to_string(),
        };

        let command = build_command(&snippet, RunMode::Escaped);
        assert!(command.starts_with("bash -c (r####'"));
        assert!(command.contains("printf \"hello\""));
        assert!(command.ends_with("'#### | str substring 1..-2)"));
    }

    #[test]
    fn remembered_shell_snippets_default_to_as_is() {
        let entry = SnippetEntry {
            snippet: ShellSnippet {
                language: "bash".to_string(),
                content: "cargo test".to_string(),
            },
            remembered_as_is: true,
        };

        assert_eq!(entry.default_run_mode(), RunMode::AsIs);
        assert_eq!(resolve_run_mode(&entry, Action::Default), RunMode::AsIs);
    }

    #[test]
    fn forcing_escaped_does_not_change_nushell_behavior() {
        let entry = SnippetEntry {
            snippet: ShellSnippet {
                language: "nushell".to_string(),
                content: "ls".to_string(),
            },
            remembered_as_is: false,
        };

        assert_eq!(resolve_run_mode(&entry, Action::ForceEscaped), RunMode::AsIs);
    }
}
