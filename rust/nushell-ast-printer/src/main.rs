use nu_parser::parse;
use nu_protocol::engine::EngineState;
use nu_protocol::{
    ast::{Block, Expr, Expression, Pipeline, PipelineElement},
    engine::StateWorkingSet
};
use std::io::{self, Read};

fn main() -> io::Result<()> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    let engine_state = EngineState::new();
    let mut working_set = StateWorkingSet::new(&engine_state);
    let block = parse(&mut working_set, None, input.as_bytes(), false);

    pretty_print_block(&block, 0);

    Ok(())
}

fn pretty_print_block(block: &Block, indent: usize) {
    println!("{}Block:", "  ".repeat(indent));
    for pipeline in &block.pipelines {
        pretty_print_pipeline(pipeline, indent + 1);
    }
}

fn pretty_print_pipeline(pipeline: &Pipeline, indent: usize) {
    println!("{}Pipeline:", "  ".repeat(indent));
    for element in &pipeline.elements {
        pretty_print_pipeline_element(element, indent + 1);
    }
}

fn pretty_print_pipeline_element(element: &PipelineElement, indent: usize) {
    println!("{}PipelineElement:", "  ".repeat(indent));
    pretty_print_expression(&element.expr, indent + 1);
}

fn pretty_print_expression(expr: &Expression, indent: usize) {
    let indent_str = "  ".repeat(indent);
    match &expr.expr {
        Expr::Call(call) => {
            println!("{}Call:", indent_str);
            println!("{}  Name: {:?}", indent_str, call.head);
            println!("{}  Arguments:", indent_str);
            for arg in &call.arguments {
                println!("{}    {:?}", indent_str, arg);
            }
        }
        Expr::ExternalCall(head, args) => {
            println!("{}ExternalCall:", indent_str);
            println!("{}  Command: {:?}", indent_str, head);
            println!("{}  Arguments:", indent_str);
            for arg in args.iter() {
                println!("{}    {:?}", indent_str, arg);
            }
        }
        Expr::Operator(op) => {
            println!("{}Operator: {:?}", indent_str, op);
        }
        Expr::BinaryOp(lhs, op, rhs) => {
            println!("{}BinaryOp:", indent_str);
            println!("{}  Operator: {:?}", indent_str, op);
            println!("{}  Left:", indent_str);
            pretty_print_expression(lhs, indent + 2);
            println!("{}  Right:", indent_str);
            pretty_print_expression(rhs, indent + 2);
        }
        Expr::UnaryNot(expr) => {
            println!("{}UnaryNot:", indent_str);
            pretty_print_expression(expr, indent + 1);
        }
        Expr::Block(block_id) => {
            println!("{}Block: (id: {})", indent_str, block_id);
        }
        Expr::Closure(block_id) => {
            println!("{}Closure: (id: {})", indent_str, block_id);
        }
        Expr::List(items) => {
            println!("{}List:", indent_str);
            for item in items {
                pretty_print_expression(item.expr(), indent + 1);
            }
        }
        Expr::Table(table) => {
            println!("{}Table:", indent_str);
            println!("{}  Columns: {:?}", indent_str, table.columns);
            println!("{}  Rows:", indent_str);
            for row in table.rows.iter() {
                println!("{}    {:?}", indent_str, row);
            }
        }
        Expr::Var(var_id) => {
            println!("{}Variable: (id: {})", indent_str, var_id);
        }
        _ => {
            println!("{}Other: {:?}", indent_str, expr.expr);
        }
    }
}
