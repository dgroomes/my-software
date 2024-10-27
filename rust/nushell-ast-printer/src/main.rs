use nushell_ast_printer::parse_nu_code;
use std::io::{self, Read};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    match parse_nu_code(&input) {
        Ok(ast) => {
            serde_json::to_writer_pretty(io::stdout(), &ast)?;
            Ok(())
        }
        Err(e) => {
            eprintln!("Error: {}", e);
            std::process::exit(1);
        }
    }
}
