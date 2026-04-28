//! Long-lived helper process that wraps Nushell's official lexer.
//!
//! The plugin spawns this binary once per IDE session and pipes lex requests over stdin /
//! stdout. The protocol is intentionally tiny so the per-keystroke cost stays in the
//! single-digit-microseconds range:
//!
//!   request:  u32 little-endian byte length, followed by exactly that many UTF-8 bytes
//!   reply:    u32 little-endian token count, followed by `count` tokens
//!   token:    u8 kind, u32 start (byte offset), u32 end (byte offset)
//!
//! All offsets are byte offsets into the request buffer (which is what `nu_parser::lex`
//! returns). The Kotlin side translates them to character offsets for IntelliJ's PSI.
//!
//! Why we sub-emit bracket and quote tokens here, instead of in Kotlin:
//!
//! `nu_parser::lex` returns a single `Item` token for things like `{ ... }`, `[ ... ]`,
//! `( ... )`, and quoted strings — the outer delimiters are already balanced by nu itself.
//! IntelliJ's brace matcher and string-literal services want to see those delimiters as
//! their own tokens. Doing the peel right here keeps the plugin's Kotlin lexer a pure
//! dispatch table over the wire kinds, with zero Nushell-grammar knowledge of its own.
//! Equally important, when nu's lexer behavior shifts (e.g. a new quote style, a new
//! bracket-like construct), we update the peel beside the upstream `lex` call rather than
//! across a process boundary.
//!
//! The binary loops forever, returning EOF only when stdin closes. The kotlin side is
//! responsible for restarting it if the process dies.

use std::io::{self, Read, Write};
use nu_parser::{lex, TokenContents};

// The token-kind tags written on the wire. They map to NuLexKind on the Kotlin side.
// IMPORTANT: do not renumber existing entries; the Kotlin side reads these as raw u8 values.
const KIND_ITEM: u8 = 0;
const KIND_COMMENT: u8 = 1;
const KIND_PIPE: u8 = 2;
const KIND_PIPE_PIPE: u8 = 3;
const KIND_ASSIGN: u8 = 4;
const KIND_REDIRECT: u8 = 5;
const KIND_SEMICOLON: u8 = 6;
const KIND_EOL: u8 = 7;
// Sub-emissions from `Item` tokens whose first byte signals structure. These let the
// IntelliJ side wire up brace-matching and string-literal services without re-lexing.
const KIND_LBRACE: u8 = 8;
const KIND_RBRACE: u8 = 9;
const KIND_LBRACKET: u8 = 10;
const KIND_RBRACKET: u8 = 11;
const KIND_LPAREN: u8 = 12;
const KIND_RPAREN: u8 = 13;
const KIND_STRING_DOUBLE: u8 = 14;
const KIND_STRING_SINGLE: u8 = 15;
const KIND_STRING_BACKTICK: u8 = 16;

fn kind_for(contents: TokenContents) -> u8 {
    match contents {
        TokenContents::Item => KIND_ITEM,
        TokenContents::Comment => KIND_COMMENT,
        TokenContents::Pipe => KIND_PIPE,
        TokenContents::PipePipe => KIND_PIPE_PIPE,
        TokenContents::AssignmentOperator => KIND_ASSIGN,
        TokenContents::ErrGreaterPipe
        | TokenContents::OutErrGreaterPipe
        | TokenContents::OutGreaterThan
        | TokenContents::OutGreaterGreaterThan
        | TokenContents::ErrGreaterThan
        | TokenContents::ErrGreaterGreaterThan
        | TokenContents::OutErrGreaterThan
        | TokenContents::OutErrGreaterGreaterThan => KIND_REDIRECT,
        TokenContents::Semicolon => KIND_SEMICOLON,
        TokenContents::Eol => KIND_EOL,
    }
}

fn read_u32(stdin: &mut impl Read) -> io::Result<Option<u32>> {
    let mut buf = [0u8; 4];
    match stdin.read_exact(&mut buf) {
        Ok(()) => Ok(Some(u32::from_le_bytes(buf))),
        Err(e) if e.kind() == io::ErrorKind::UnexpectedEof => Ok(None),
        Err(e) => Err(e),
    }
}

fn write_token(out: &mut impl Write, kind: u8, start: usize, end: usize) -> io::Result<()> {
    let mut record = [0u8; 9];
    record[0] = kind;
    record[1..5].copy_from_slice(&(start as u32).to_le_bytes());
    record[5..9].copy_from_slice(&(end as u32).to_le_bytes());
    out.write_all(&record)
}

/// Decide whether an `Item` token should be sub-emitted as bracket-open / inner / bracket-close
/// or as a single quoted-string token. Returns the wire kinds to emit; an empty Vec means
/// "emit a plain ITEM token spanning the whole span".
///
/// The caller guarantees `span` is non-empty. The detection uses only the first and last
/// byte of the span — nu's lexer has already balanced the delimiters in producing this
/// `Item`, so we don't need to re-lex anything.
fn split_item(input: &[u8], start: usize, end: usize) -> Vec<(u8, usize, usize)> {
    debug_assert!(end > start);
    let first = input[start];
    let last = input[end - 1];

    let bracket = match first {
        b'{' if last == b'}' => Some((KIND_LBRACE, KIND_RBRACE)),
        b'[' if last == b']' => Some((KIND_LBRACKET, KIND_RBRACKET)),
        b'(' if last == b')' => Some((KIND_LPAREN, KIND_RPAREN)),
        _ => None,
    };
    if let Some((open_kind, close_kind)) = bracket {
        if end - start >= 2 {
            let mut out = Vec::with_capacity(3);
            out.push((open_kind, start, start + 1));
            if end - start > 2 {
                out.push((KIND_ITEM, start + 1, end - 1));
            }
            out.push((close_kind, end - 1, end));
            return out;
        }
    }

    let string_kind = match first {
        b'"' => Some(KIND_STRING_DOUBLE),
        b'\'' => Some(KIND_STRING_SINGLE),
        b'`' => Some(KIND_STRING_BACKTICK),
        _ => None,
    };
    if let Some(k) = string_kind {
        return vec![(k, start, end)];
    }

    Vec::new()
}

fn handle_request(input: &[u8], out: &mut impl Write) -> io::Result<()> {
    // We pass `skip_comment: false` because IntelliJ wants to know about comment ranges
    // (so it can fold them, color them, and toggle them via Ctrl+/). The other knobs are
    // left at their defaults — we want the same lexer behavior as `nu` itself.
    let (tokens, _err) = lex(input, 0, &[], &[], false);

    // Two-pass over `tokens` to compute the on-the-wire count. Each plain token contributes
    // one record; an `Item` we decide to split contributes 1 (bracketed inner-empty), 2, or 3.
    let mut emissions: Vec<(u8, usize, usize)> = Vec::with_capacity(tokens.len() + 4);
    for token in &tokens {
        let start = token.span.start;
        let end = token.span.end;
        if matches!(token.contents, TokenContents::Item) && end > start {
            let split = split_item(input, start, end);
            if split.is_empty() {
                emissions.push((KIND_ITEM, start, end));
            } else {
                emissions.extend(split);
            }
        } else {
            emissions.push((kind_for(token.contents), start, end));
        }
    }

    let count = emissions.len() as u32;
    out.write_all(&count.to_le_bytes())?;
    for (kind, start, end) in emissions {
        write_token(out, kind, start, end)?;
    }
    out.flush()?;
    Ok(())
}

fn main() -> io::Result<()> {
    let mut stdin = io::stdin().lock();
    let mut stdout = io::stdout().lock();
    let mut buf = Vec::with_capacity(64 * 1024);

    loop {
        let len = match read_u32(&mut stdin)? {
            Some(n) => n as usize,
            None => return Ok(()),
        };
        buf.resize(len, 0u8);
        stdin.read_exact(&mut buf)?;
        handle_request(&buf, &mut stdout)?;
    }
}
