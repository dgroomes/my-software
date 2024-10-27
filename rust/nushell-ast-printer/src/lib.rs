mod ast_printer;
mod error;

pub use ast_printer::{AstOutput, AstPrinter, NodeType};
pub use error::AstPrinterError;

use new_nu_parser::{compiler::Compiler, parser::Parser};
use new_nu_parser::parser::NodeId;

pub fn parse_nu_code(input: &str) -> Result<AstOutput, AstPrinterError> {
    let mut compiler = Compiler::new();
    let span_offset = compiler.span_offset();
    compiler.add_file("<input>", input.as_bytes());

    let parser = Parser::new(compiler, span_offset);
    let compiler = parser.parse();

    if !compiler.errors.is_empty() {
        let error_messages = compiler
            .errors
            .iter()
            .map(|e| e.message.clone())
            .collect::<Vec<_>>();
        return Err(AstPrinterError::ParserError(error_messages.join("\n")));
    }

    if compiler.ast_nodes.is_empty() {
        return Ok(AstOutput::new(NodeType::Block));
    }

    let printer = AstPrinter::new(&compiler);
    // Corrected line: Get the NodeId of the root node
    let root_node_id = NodeId(compiler.ast_nodes.len() - 1);
    Ok(printer.process_node(root_node_id))
}

#[cfg(test)]
mod test_utils;
