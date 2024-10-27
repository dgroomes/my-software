use thiserror::Error;

#[derive(Debug, Error)]
pub enum AstPrinterError {
    #[error("Parser error: {0}")]
    ParserError(String),

    #[error("Invalid AST node: {0}")]
    InvalidNode(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("JSON serialization error: {0}")]
    JsonError(#[from] serde_json::Error),
}
