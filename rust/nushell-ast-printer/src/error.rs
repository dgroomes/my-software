use thiserror::Error;

#[derive(Debug, Error)]
pub enum AstPrinterError {
    #[error("Parser error(s): {0}")]
    ParserError(String),

    #[error("Invalid AST node: {0}")]
    InvalidNode(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("JSON serialization error: {0}")]
    JsonError(#[from] serde_json::Error),
}

impl From<Vec<String>> for AstPrinterError {
    fn from(errors: Vec<String>) -> Self {
        AstPrinterError::ParserError(errors.join("\n"))
    }
}
