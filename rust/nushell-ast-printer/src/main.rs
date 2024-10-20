use nu_parser::parse;
use nu_protocol::engine::{EngineState, StateWorkingSet};
use std::error::Error;
use std::io::{self, Read};

fn main() -> Result<(), Box<dyn Error>> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    let engine_state = EngineState::new();
    let mut working_set = StateWorkingSet::new(&engine_state);
    let block = parse(&mut working_set, None, input.as_bytes(), false);

    serde_json::to_writer_pretty(io::stdout(), &*block)?;
    Ok(())
}
