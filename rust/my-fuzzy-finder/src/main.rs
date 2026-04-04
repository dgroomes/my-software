use std::collections::HashSet;
use std::env;
use std::fs::{File, OpenOptions};
use std::io::{self, BufRead, BufReader, Write};
use std::time::Duration;

use crossterm::cursor::{Hide, Show};
use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyModifiers};
use crossterm::execute;
use crossterm::terminal::{
    disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen,
};
use ratatui::backend::CrosstermBackend;
use ratatui::layout::{Constraint, Direction, Layout, Margin};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span, Text};
use ratatui::widgets::{Paragraph, Wrap};
use ratatui::Terminal;
use serde::Serialize;
use unicode_width::UnicodeWidthChar;
use my_fuzzy_finder_lib as matcher;

const NO_MATCH_EXIT_CODE: i32 = 1;
const NO_SELECTION_EXIT_CODE: i32 = 130;
const PROMPT: &str = "Filter: ";
const QUERY_CHAR_LIMIT: usize = 64;
const ACCENT_COLOR: Color = Color::Rgb(0xDA, 0x5C, 0xE4);

#[derive(Clone, Debug)]
struct Match {
    index: usize,
    positions: Vec<usize>,
}

#[derive(Debug, Default)]
struct Logger {
    file: Option<File>,
}

impl Logger {
    fn new(enabled: bool) -> io::Result<Self> {
        let file = if enabled {
            Some(
                OpenOptions::new()
                    .create(true)
                    .append(true)
                    .open("my-fuzzy-finder.log")?,
            )
        } else {
            None
        };

        Ok(Self { file })
    }

    fn log(&mut self, message: impl AsRef<str>) {
        if let Some(file) = &mut self.file {
            let _ = writeln!(file, "{}", message.as_ref());
        }
    }
}

#[derive(Debug)]
struct App {
    items: Vec<String>,
    query: String,
    matches: Vec<Match>,
    pages: Vec<Vec<Match>>,
    item: Option<usize>,
    page: usize,
    page_item: usize,
    completed_with_selection: bool,
    logger: Logger,
}

impl App {
    fn new(items: Vec<String>, logger: Logger) -> Self {
        Self {
            items,
            query: String::new(),
            matches: Vec::new(),
            pages: Vec::new(),
            item: None,
            page: 0,
            page_item: 0,
            completed_with_selection: false,
            logger,
        }
    }

    fn selected_item(&self) -> Option<&String> {
        self.item.and_then(|index| self.items.get(index))
    }

    fn render(&self, frame: &mut ratatui::Frame<'_>) {
        let area = if frame.area().height > 10 && frame.area().width > 50 {
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
            .constraints([Constraint::Length(1), Constraint::Min(1)])
            .split(area);

        let cursor = Span::styled("█", Style::default().fg(ACCENT_COLOR));
        let input = Paragraph::new(Line::from(vec![
            Span::styled(PROMPT, Style::default().fg(Color::DarkGray)),
            Span::raw(self.query.clone()),
            cursor,
        ]));
        frame.render_widget(input, sections[0]);

        let content = if self.pages.is_empty() {
            Text::from(Line::from(Span::styled(
                "No matches.",
                Style::default().fg(Color::DarkGray),
            )))
        } else {
            let page = &self.pages[self.page];
            let text_width = sections[1].width.saturating_sub(2).max(1);
            let mut lines = Vec::new();

            for (index, item_match) in page.iter().enumerate() {
                let selected = index == self.page_item;
                lines.extend(render_item(
                    &self.items[item_match.index],
                    &item_match.positions,
                    selected,
                    text_width,
                ));
            }

            Text::from(lines)
        };

        let content = Paragraph::new(content).wrap(Wrap { trim: false });
        frame.render_widget(content, sections[1]);
    }

    fn refresh_matches(&mut self, height: u16, width: u16) {
        if self.query.is_empty() {
            self.matches.clear();
        } else {
            self.matches = match_all(&self.query, &self.items);
        }
        self.reflow(height, width);
    }

    fn reflow(&mut self, height: u16, width: u16) {
        if self.items.is_empty() {
            self.pages.clear();
            self.item = None;
            self.page = 0;
            self.page_item = 0;
            return;
        }

        let matches = if self.query.is_empty() {
            self.items
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

        let use_margin = height > 10 && width > 50;
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
        let available_height = inner_height.saturating_sub(1).max(1) as usize;
        let available_width = inner_width.saturating_sub(2).max(1) as usize;

        let previous_item = self.item.unwrap_or(0);
        let mut closest_distance = self.items.len();
        let mut pages: Vec<Vec<Match>> = Vec::new();
        let mut page: Vec<Match> = Vec::new();
        let mut height_budget = available_height;
        let mut new_selected_item = None;
        let mut new_selected_page = 0usize;
        let mut new_selected_page_item = 0usize;

        for item_match in matches {
            let item_height = wrapped_height(&self.items[item_match.index], available_width);
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
            KeyCode::Enter => {
                self.completed_with_selection = true;
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
                self.logger.log(format!("query={}", self.query));
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
                self.logger.log(format!("query={}", self.query));
                self.refresh_matches(height, width);
                false
            }
            _ => false,
        }
    }
}

#[derive(Debug)]
struct ParsedArgs {
    debug: bool,
    example: bool,
    json_in: bool,
    json_out: bool,
    show_help: bool,
}

#[derive(Serialize)]
struct ReturnItem<'a> {
    index: usize,
    value: &'a str,
}

struct TerminalGuard {
    terminal: Terminal<CrosstermBackend<File>>,
}

impl TerminalGuard {
    fn new(tty: File) -> io::Result<Self> {
        enable_raw_mode()?;
        let backend = CrosstermBackend::new(tty);
        let mut terminal = Terminal::new(backend)?;
        execute!(terminal.backend_mut(), EnterAlternateScreen, Hide)?;
        terminal.clear()?;
        Ok(Self { terminal })
    }

    fn terminal_mut(&mut self) -> &mut Terminal<CrosstermBackend<File>> {
        &mut self.terminal
    }
}

impl Drop for TerminalGuard {
    fn drop(&mut self) {
        let _ = disable_raw_mode();
        let _ = execute!(self.terminal.backend_mut(), Show, LeaveAlternateScreen);
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

    let items = read_items(&args)?;
    if items.is_empty() {
        return Ok(NO_MATCH_EXIT_CODE);
    }

    let logger = Logger::new(args.debug)?;
    let mut app = App::new(items, logger);

    let tty = OpenOptions::new().read(true).write(true).open("/dev/tty")?;
    let mut terminal = TerminalGuard::new(tty.try_clone()?)?;
    let initial_area = terminal.terminal_mut().size()?;
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

    if !app.completed_with_selection {
        return Ok(NO_SELECTION_EXIT_CODE);
    }

    let Some(index) = app.item else {
        return Ok(NO_MATCH_EXIT_CODE);
    };
    let selected = ReturnItem {
        index,
        value: app.selected_item().expect("selected item must exist"),
    };

    if args.json_out {
        serde_json::to_writer(io::stdout(), &selected)?;
        println!();
    } else {
        print!("{}", selected.value);
    }

    Ok(0)
}

fn parse_args(args: Vec<String>) -> Result<ParsedArgs, Box<dyn std::error::Error>> {
    let mut parsed = ParsedArgs {
        debug: false,
        example: false,
        json_in: false,
        json_out: false,
        show_help: false,
    };

    for arg in args {
        match arg.as_str() {
            "--debug" => parsed.debug = true,
            "--example" => parsed.example = true,
            "--json-in" => parsed.json_in = true,
            "--json-out" => parsed.json_out = true,
            "--help" | "-h" => {
                println!("Usage: my-fuzzy-finder [--debug] [--example] [--json-in] [--json-out]");
                parsed.show_help = true;
            }
            _ => return Err(format!("unknown argument: {arg}").into()),
        }
    }

    Ok(parsed)
}

fn read_items(args: &ParsedArgs) -> Result<Vec<String>, Box<dyn std::error::Error>> {
    if args.example {
        return Ok(vec![
            "Eight hours of sleep".to_string(),
            "French press".to_string(),
            "Dear Reader,\nHello.".to_string(),
            "Kombucha brewing".to_string(),
            "Milk crates".to_string(),
            "Morning temperature: 72° F".to_string(),
            "Pour over coffee".to_string(),
            "Shampoo".to_string(),
            "🏓 Table 🏓 tennis 🏓".to_string(),
            "Terrycloth".to_string(),
        ]);
    }

    if args.json_in {
        let items = serde_json::from_reader(io::stdin())?;
        return Ok(items);
    }

    let reader = BufReader::new(io::stdin());
    let mut items = Vec::new();
    for line in reader.lines() {
        items.push(line?);
    }
    Ok(items)
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

fn render_item(item: &str, matched_positions: &[usize], selected: bool, width: u16) -> Vec<Line<'static>> {
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
