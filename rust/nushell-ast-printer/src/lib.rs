mod ast_printer;
mod error;

pub use ast_printer::{AstOutput, AstPrinter};
pub use error::AstPrinterError;

use new_nu_parser::{compiler::Compiler, parser::Parser};

pub fn parse_nu_code(input: &str) -> Result<AstOutput, AstPrinterError> {
    let mut compiler = Compiler::new();
    let span_offset = compiler.span_offset();
    compiler.add_file("<input>", input.as_bytes());

    let parser = Parser::new(compiler, span_offset);
    let compiler = parser.parse();

    if !compiler.errors.is_empty() {
        return Err(AstPrinterError::ParserError(
            compiler
                .errors
                .iter()
                .map(|e| e.message.clone())
                .collect::<Vec<_>>()
                .join("\n"),
        ));
    }

    if compiler.ast_nodes.is_empty() {
        return Ok(AstOutput::new("Empty"));
    }

    let printer = AstPrinter::new(&compiler);
    Ok(printer.process_node(compiler.ast_nodes.len() - 1))
}

#[cfg(test)]
mod test_utils;
