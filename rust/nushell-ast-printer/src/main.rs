use new_nu_parser::{
    compiler::Compiler,
    parser::{AstNode, NodeId, Parser},
};
use serde::Serialize;
use std::io::{self, Read};
use std::error::Error;

#[derive(Serialize)]
struct AstOutput {
    #[serde(rename = "type")]
    node_type: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    value: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    children: Vec<AstOutput>,
}

fn process_node(compiler: &Compiler, node_id: NodeId) -> AstOutput {
    let node = &compiler.ast_nodes[node_id.0];

    match node {
        AstNode::Int | AstNode::Float | AstNode::String | AstNode::Name | AstNode::Variable | AstNode::True | AstNode::False => {
            // Handle literal nodes by capturing their source text
            let span = compiler.get_span(node_id);
            let value = String::from_utf8_lossy(&compiler.source[span.start..span.end]).into_owned();

            AstOutput {
                node_type: match node {
                    AstNode::Int => "Integer",
                    AstNode::Float => "Float",
                    AstNode::String => "String",
                    AstNode::Name => "Name",
                    AstNode::Variable => "Variable",
                    AstNode::True | AstNode::False => "Boolean",
                    _ => unreachable!()
                }.to_string(),
                name: None,
                value: Some(value),
                children: vec![],
            }
        }

        AstNode::Let { variable_name, ty, initializer, is_mutable } => {
            let mut children = vec![process_node(compiler, *variable_name)];
            if let Some(type_node) = ty {
                children.push(process_node(compiler, *type_node));
            }
            children.push(process_node(compiler, *initializer));

            AstOutput {
                node_type: if *is_mutable { "MutableLet" } else { "Let" }.to_string(),
                name: None,
                value: None,
                children,
            }
        }

        AstNode::Def { name, params, return_ty, block } => {
            let mut children = vec![process_node(compiler, *name)];
            children.push(process_node(compiler, *params));
            if let Some(ret_ty) = return_ty {
                children.push(process_node(compiler, *ret_ty));
            }
            children.push(process_node(compiler, *block));

            AstOutput {
                node_type: "Definition".to_string(),
                name: None,
                value: None,
                children,
            }
        }

        AstNode::BinaryOp { lhs, op, rhs } => {
            let op_name = match compiler.get_node(*op) {
                AstNode::Plus => "Add",
                AstNode::Minus => "Subtract",
                AstNode::Multiply => "Multiply",
                AstNode::Divide => "Divide",
                AstNode::Equal => "Equal",
                AstNode::NotEqual => "NotEqual",
                AstNode::LessThan => "LessThan",
                AstNode::GreaterThan => "GreaterThan",
                AstNode::And => "And",
                AstNode::Or => "Or",
                _ => "UnknownOp"
            };

            AstOutput {
                node_type: "BinaryOp".to_string(),
                name: Some(op_name.to_string()),
                value: None,
                children: vec![
                    process_node(compiler, *lhs),
                    process_node(compiler, *rhs)
                ],
            }
        }

        AstNode::List(items) => AstOutput {
            node_type: "List".to_string(),
            name: None,
            value: None,
            children: items.iter().map(|id| process_node(compiler, *id)).collect(),
        },

        AstNode::Block(block_id) => {
            let block = &compiler.blocks[block_id.0];
            AstOutput {
                node_type: "Block".to_string(),
                name: None,
                value: None,
                children: block.nodes.iter().map(|id| process_node(compiler, *id)).collect(),
            }
        }

        AstNode::If { condition, then_block, else_block } => {
            let mut children = vec![
                process_node(compiler, *condition),
                process_node(compiler, *then_block)
            ];
            if let Some(else_node) = else_block {
                children.push(process_node(compiler, *else_node));
            }

            AstOutput {
                node_type: "If".to_string(),
                name: None,
                value: None,
                children,
            }
        }

        AstNode::Call { parts } => {
            AstOutput {
                node_type: "Call".to_string(),
                name: None,
                value: None,
                children: parts.iter().map(|id| process_node(compiler, *id)).collect(),
            }
        }

        _ => AstOutput {
            node_type: "Unknown".to_string(),
            name: Some(format!("{:?}", node)),
            value: None,
            children: vec![],
        }
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    let mut nu_snippet = String::new();
    io::stdin().read_to_string(&mut nu_snippet)?;

    let mut compiler = Compiler::new();
    let span_offset = compiler.span_offset();
    compiler.add_file("<stdin>", nu_snippet.as_bytes());

    let parser = Parser::new(compiler, span_offset);
    let compiler = parser.parse();

    if !compiler.errors.is_empty() {
        eprintln!("Parser errors:");
        for error in &compiler.errors {
            eprintln!("  {}", error.message);
        }
        std::process::exit(1);
    }

    if compiler.ast_nodes.is_empty() {
        serde_json::to_writer_pretty(
            io::stdout(),
            &AstOutput {
                node_type: "Empty".to_string(),
                name: None,
                value: None,
                children: vec![],
            },
        )?;
        return Ok(());
    }

    let last_node = NodeId(compiler.ast_nodes.len() - 1);

    let output = process_node(&compiler, last_node);
    serde_json::to_writer_pretty(io::stdout(), &output)?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::Value;

    fn parse_to_json(input: &str) -> Value {
        let mut compiler = Compiler::new();
        let span_offset = compiler.span_offset();
        compiler.add_file("<test>", input.as_bytes());

        let parser = Parser::new(compiler, span_offset);
        let compiler = parser.parse();

        if !compiler.errors.is_empty() {
            panic!("Parser errors: {:?}", compiler.errors);
        }

        if compiler.ast_nodes.is_empty() {
            return serde_json::json!({
                "type": "Empty",
                "children": []
            });
        }

        let last_node = NodeId(compiler.ast_nodes.len() - 1);
        let output = process_node(&compiler, last_node);
        serde_json::to_value(output).unwrap()
    }

    /// Helper function to extract just the essential parts we want to test
    fn simplify_json(json: Value) -> Value {
        match json {
            Value::Object(mut map) => {
                // Remove empty fields
                map.retain(|_, v| !v.is_null() && v != &Value::Array(vec![]));

                // Recursively simplify children
                if let Some(Value::Array(children)) = map.get("children") {
                    let simplified_children: Vec<Value> = children.iter()
                        .map(|child| simplify_json(child.clone()))
                        .collect();
                    map.insert("children".to_string(), Value::Array(simplified_children));
                }

                Value::Object(map)
            }
            Value::Array(arr) => {
                Value::Array(arr.into_iter().map(simplify_json).collect())
            }
            _ => json
        }
    }

    #[test]
    fn test_simple_string() {
        let json = parse_to_json("\"hello world\"");
        let simplified = simplify_json(json);
        assert_eq!(simplified, serde_json::json!({
            "type": "Block",
            "children": [{
                "type": "String",
                "value": "\"hello world\""
            }]
        }));
    }

    #[test]
    fn test_let_binding() {
        let json = parse_to_json("let x = 42");
        let simplified = simplify_json(json);
        assert_eq!(simplified, serde_json::json!({
            "type": "Block",
            "children": [{
                "type": "Let",
                "children": [
                    {
                        "type": "Variable",
                        "value": "x"
                    },
                    {
                        "type": "Integer",
                        "value": "42"
                    }
                ]
            }]
        }));
    }

    #[test]
    fn test_mutable_let() {
        let json = parse_to_json("mut y = 3.14");
        let simplified = simplify_json(json);
        assert_eq!(simplified, serde_json::json!({
            "type": "Block",
            "children": [{
                "type": "MutableLet",
                "children": [
                    {
                        "type": "Variable",
                        "value": "y"
                    },
                    {
                        "type": "Float",
                        "value": "3.14"
                    }
                ]
            }]
        }));
    }

    #[test]
    fn test_binary_operation() {
        let json = parse_to_json("1 + 2");
        let simplified = simplify_json(json);
        assert_eq!(simplified, serde_json::json!({
            "type": "Block",
            "children": [{
                "type": "BinaryOp",
                "name": "Add",
                "children": [
                    {
                        "type": "Integer",
                        "value": "1"
                    },
                    {
                        "type": "Integer",
                        "value": "2"
                    }
                ]
            }]
        }));
    }

    #[test]
    fn test_simple_command() {
        let json = parse_to_json("echo hello world");
        let simplified = simplify_json(json);
        assert_eq!(simplified, serde_json::json!({
            "type": "Block",
            "children": [{
                "type": "Call",
                "children": [
                    {
                        "type": "Name",
                        "value": "echo"
                    },
                    {
                        "type": "Name",
                        "value": "hello"
                    },
                    {
                        "type": "Name",
                        "value": "world"
                    }
                ]
            }]
        }));
    }

    #[test]
    fn test_if_statement() {
        let json = parse_to_json("if true { 42 }");
        let simplified = simplify_json(json);
        assert_eq!(simplified, serde_json::json!({
            "type": "Block",
            "children": [{
                "type": "If",
                "children": [
                    {
                        "type": "Boolean",
                        "value": "true"
                    },
                    {
                        "type": "Block",
                        "children": [{
                            "type": "Integer",
                            "value": "42"
                        }]
                    }
                ]
            }]
        }));
    }

    #[test]
    fn test_if_else() {
        let json = parse_to_json("if false { 0 } else { 1 }");
        let simplified = simplify_json(json);
        assert_eq!(simplified, serde_json::json!({
            "type": "Block",
            "children": [{
                "type": "If",
                "children": [
                    {
                        "type": "Boolean",
                        "value": "false"
                    },
                    {
                        "type": "Block",
                        "children": [{
                            "type": "Integer",
                            "value": "0"
                        }]
                    },
                    {
                        "type": "Block",
                        "children": [{
                            "type": "Integer",
                            "value": "1"
                        }]
                    }
                ]
            }]
        }));
    }

    #[test]
    fn test_list() {
        let json = parse_to_json("[1, 2, 3]");
        let simplified = simplify_json(json);
        assert_eq!(simplified, serde_json::json!({
            "type": "Block",
            "children": [{
                "type": "List",
                "children": [
                    {
                        "type": "Integer",
                        "value": "1"
                    },
                    {
                        "type": "Integer",
                        "value": "2"
                    },
                    {
                        "type": "Integer",
                        "value": "3"
                    }
                ]
            }]
        }));
    }

    #[test]
    fn test_parse_error() {
        // This should panic with parser errors
        std::panic::catch_unwind(|| {
            parse_to_json("let = 42"); // Missing variable name
        }).expect_err("Expected parser error for invalid syntax");
    }
}
