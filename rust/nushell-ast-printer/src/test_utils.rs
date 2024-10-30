#[cfg(test)]
pub mod tests {
    use super::super::*;
    use pretty_assertions::assert_eq;
    use serde_json::Value;

    pub fn parse_to_json(input: &str) -> Result<Value, AstPrinterError> {
        let output = parse_nu_code(input)?;
        Ok(serde_json::to_value(output)?)
    }

    pub fn simplify_json(json: Value) -> Value {
        match json {
            Value::Object(mut map) => {
                // Remove empty fields
                map.retain(|_, v| !v.is_null() && v != &Value::Array(vec![]));

                // Recursively simplify children
                if let Some(Value::Array(children)) = map.get_mut("children") {
                    *children = children
                        .iter()
                        .map(|child| simplify_json(child.clone()))
                        .collect();
                }

                Value::Object(map)
            }
            Value::Array(arr) => Value::Array(arr.into_iter().map(simplify_json).collect()),
            _ => json,
        }
    }

    #[test]
    fn test_simple_string() {
        let json = parse_to_json("\"hello world\"").unwrap();
        let simplified = simplify_json(json);
        assert_eq!(
            simplified,
            serde_json::json!({
                "type": "Block",
                "children": [{
                    "type": "String",
                    "value": "hello world"
                }]
            })
        );
    }

    #[test]
    fn test_let_binding() {
        let json = parse_to_json("let x = 42").unwrap();
        let simplified = simplify_json(json);
        assert_eq!(
            simplified,
            serde_json::json!({
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
            })
        );
    }

    #[test]
    fn test_mutable_let() {
        let json = parse_to_json("mut y = 3.14").unwrap();
        let simplified = simplify_json(json);
        assert_eq!(
            simplified,
            serde_json::json!({
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
            })
        );
    }

    #[test]
    fn test_binary_operation() {
        let json = parse_to_json("1 + 2").unwrap();
        let simplified = simplify_json(json);
        assert_eq!(
            simplified,
            serde_json::json!({
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
            })
        );
    }

    #[test]
    fn test_simple_command() {
        let json = parse_to_json("echo hello world").unwrap();
        let simplified = simplify_json(json);
        assert_eq!(
            simplified,
            serde_json::json!({
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
            })
        );
    }

    #[test]
    fn test_if_statement() {
        let json = parse_to_json("if true { 42 }").unwrap();
        let simplified = simplify_json(json);
        assert_eq!(
            simplified,
            serde_json::json!({
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
            })
        );
    }

    #[test]
    fn test_if_else() {
        let json = parse_to_json("if false { 0 } else { 1 }").unwrap();
        let simplified = simplify_json(json);
        assert_eq!(
            simplified,
            serde_json::json!({
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
            })
        );
    }

    #[test]
    fn test_list() {
        let json = parse_to_json("[1, 2, 3]").unwrap();
        let simplified = simplify_json(json);
        assert_eq!(
            simplified,
            serde_json::json!({
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
            })
        );
    }

    #[test]
    fn test_parse_error() {
        let result = parse_to_json("let = 42"); // Missing variable name
        assert!(
            matches!(result, Err(AstPrinterError::ParserError(_))),
            "Expected ParserError but got {:?}",
            result
        );

        if let Err(AstPrinterError::ParserError(error_msg)) = result {
            // Verify the error message contains expected keywords
            assert!(
                error_msg.contains("variable"),
                "Error should mention missing variable, got: {}",
                error_msg
            );
        }
    }
}
