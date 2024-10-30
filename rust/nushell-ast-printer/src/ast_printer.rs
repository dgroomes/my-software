use new_nu_parser::{
    compiler::Compiler,
    parser::{AstNode, BlockId, NodeId},
};
use serde::Serialize;

#[derive(Debug, Serialize)]
#[serde(rename_all = "PascalCase")]
pub enum NodeType {
    Integer,
    Float,
    String,
    Name,
    Variable,
    Boolean,
    Let,
    MutableLet,
    Definition,
    BinaryOp,
    List,
    Block,
    If,
    Call,
    Unknown,
}

#[derive(Debug, Serialize)]
pub struct AstOutput {
    #[serde(rename = "type")]
    node_type: NodeType,
    #[serde(skip_serializing_if = "Option::is_none")]
    name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    value: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    children: Vec<AstOutput>,
}

impl AstOutput {
    pub fn new(node_type: NodeType) -> Self {
        Self {
            node_type,
            name: None,
            value: None,
            children: Vec::new(),
        }
    }

    pub fn with_name(mut self, name: impl Into<String>) -> Self {
        self.name = Some(name.into());
        self
    }

    pub fn with_value(mut self, value: impl Into<String>) -> Self {
        self.value = Some(value.into());
        self
    }

    pub fn with_children(mut self, children: Vec<AstOutput>) -> Self {
        self.children = children;
        self
    }
}

pub struct AstPrinter<'a> {
    compiler: &'a Compiler,
}

impl<'a> AstPrinter<'a> {
    pub fn new(compiler: &'a Compiler) -> Self {
        Self { compiler }
    }

    pub fn process_node(&self, node_id: NodeId) -> AstOutput {
        match self.compiler.get_node(node_id) {
            AstNode::Int | AstNode::Float | AstNode::String | AstNode::Name | AstNode::Variable => {
                self.process_literal_node(node_id)
            }
            AstNode::True | AstNode::False => self.process_boolean_node(node_id),
            AstNode::Let {
                variable_name,
                ty,
                initializer,
                is_mutable,
            } => self.process_let_node(*variable_name, ty, *initializer, *is_mutable),
            AstNode::Def {
                name,
                params,
                return_ty,
                block,
            } => self.process_def_node(*name, *params, *return_ty, *block),
            AstNode::BinaryOp { lhs, op, rhs } => self.process_binary_op(*lhs, *op, *rhs),
            AstNode::List(items) => self.process_list_node(items),
            AstNode::Block(block_id) => self.process_block_node(*block_id),
            AstNode::If {
                condition,
                then_block,
                else_block,
            } => self.process_if_node(*condition, *then_block, *else_block),
            AstNode::Call { parts } => self.process_call_node(parts),
            other => AstOutput::new(NodeType::Unknown).with_name(format!("{:?}", other)),
        }
    }

    fn get_node_value(&self, node_id: NodeId) -> String {
        let span = self.compiler.get_span(node_id);
        String::from_utf8_lossy(&self.compiler.source[span.start..span.end]).into_owned()
    }

    fn process_literal_node(&self, node_id: NodeId) -> AstOutput {
        let mut value = self.get_node_value(node_id);

        let node_type = match self.compiler.get_node(node_id) {
            AstNode::Int => NodeType::Integer,
            AstNode::Float => NodeType::Float,
            AstNode::String => NodeType::String,
            AstNode::Name => NodeType::Name,
            AstNode::Variable => NodeType::Variable,
            _ => unreachable!(),
        };

        // If node is String, strip the quotes
        if let NodeType::String = node_type {
            if (value.starts_with('"') && value.ends_with('"')) || (value.starts_with('\'') && value.ends_with('\'')) {
                value = value[1..value.len() - 1].to_string();
            }
        }

        AstOutput::new(node_type).with_value(value)
    }

    fn process_boolean_node(&self, node_id: NodeId) -> AstOutput {
        let value = self.get_node_value(node_id);
        AstOutput::new(NodeType::Boolean).with_value(value)
    }

    fn process_let_node(
        &self,
        variable_name: NodeId,
        ty: &Option<NodeId>,
        initializer: NodeId,
        is_mutable: bool,
    ) -> AstOutput {
        let mut children = vec![self.process_node(variable_name)];

        if let Some(type_node) = ty {
            children.push(self.process_node(*type_node));
        }
        children.push(self.process_node(initializer));

        let node_type = if is_mutable {
            NodeType::MutableLet
        } else {
            NodeType::Let
        };

        AstOutput::new(node_type).with_children(children)
    }

    fn process_def_node(
        &self,
        name: NodeId,
        params: NodeId,
        return_ty: Option<NodeId>,
        block: NodeId,
    ) -> AstOutput {
        let mut children = vec![self.process_node(name), self.process_node(params)];

        if let Some(ret_ty) = return_ty {
            children.push(self.process_node(ret_ty));
        }
        children.push(self.process_node(block));

        AstOutput::new(NodeType::Definition).with_children(children)
    }

    fn process_binary_op(&self, lhs: NodeId, op: NodeId, rhs: NodeId) -> AstOutput {
        let op_name = match self.compiler.get_node(op) {
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
            _ => "UnknownOp",
        };

        AstOutput::new(NodeType::BinaryOp)
            .with_name(op_name)
            .with_children(vec![self.process_node(lhs), self.process_node(rhs)])
    }

    fn process_list_node(&self, items: &[NodeId]) -> AstOutput {
        AstOutput::new(NodeType::List)
            .with_children(items.iter().map(|&id| self.process_node(id)).collect())
    }

    fn process_block_node(&self, block_id: BlockId) -> AstOutput {
        let block = &self.compiler.blocks[block_id.0];
        AstOutput::new(NodeType::Block)
            .with_children(block.nodes.iter().map(|&id| self.process_node(id)).collect())
    }

    fn process_if_node(
        &self,
        condition: NodeId,
        then_block: NodeId,
        else_block: Option<NodeId>,
    ) -> AstOutput {
        let mut children = vec![self.process_node(condition), self.process_node(then_block)];

        if let Some(else_node) = else_block {
            children.push(self.process_node(else_node));
        }

        AstOutput::new(NodeType::If).with_children(children)
    }

    fn process_call_node(&self, parts: &[NodeId]) -> AstOutput {
        AstOutput::new(NodeType::Call)
            .with_children(parts.iter().map(|&id| self.process_node(id)).collect())
    }
}
