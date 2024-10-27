use new_nu_parser::{
    compiler::Compiler,
    parser::{AstNode, NodeId},
};
use new_nu_parser::parser::BlockId;
use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct AstOutput {
    #[serde(rename = "type")]
    node_type: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    value: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    children: Vec<AstOutput>,
}

impl AstOutput {
    pub fn new(node_type: &str) -> Self {
        Self {
            node_type: node_type.to_string(),
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

    pub fn process_node(&self, node_idx: usize) -> AstOutput {
        let node_id = NodeId(node_idx);
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
            } => self.process_let_node(node_id, *variable_name, ty, *initializer, *is_mutable),
            AstNode::Def {
                name,
                params,
                return_ty,
                block,
            } => self.process_def_node(node_id, *name, *params, *return_ty, *block),
            AstNode::BinaryOp { lhs, op, rhs } => self.process_binary_op(node_id, *lhs, *op, *rhs),
            AstNode::List(items) => self.process_list_node(node_id, items),
            AstNode::Block(block_id) => self.process_block_node(node_id, *block_id),
            AstNode::If {
                condition,
                then_block,
                else_block,
            } => self.process_if_node(node_id, *condition, *then_block, *else_block),
            AstNode::Call { parts } => self.process_call_node(node_id, parts),
            other => AstOutput::new("Unknown").with_name(format!("{:?}", other)),
        }
    }

    fn process_literal_node(&self, node_id: NodeId) -> AstOutput {
        let span = self.compiler.get_span(node_id);
        let value = String::from_utf8_lossy(&self.compiler.source[span.start..span.end]);

        let node_type = match self.compiler.get_node(node_id) {
            AstNode::Int => "Integer",
            AstNode::Float => "Float",
            AstNode::String => "String",
            AstNode::Name => "Name",
            AstNode::Variable => "Variable",
            _ => unreachable!(),
        };

        AstOutput::new(node_type).with_value(value.into_owned())
    }

    fn process_boolean_node(&self, node_id: NodeId) -> AstOutput {
        let span = self.compiler.get_span(node_id);
        let value = String::from_utf8_lossy(&self.compiler.source[span.start..span.end]);
        AstOutput::new("Boolean").with_value(value.into_owned())
    }

    fn process_let_node(
        &self,
        _node_id: NodeId,
        variable_name: NodeId,
        ty: &Option<NodeId>,
        initializer: NodeId,
        is_mutable: bool,
    ) -> AstOutput {
        let mut children = vec![self.process_node(variable_name.0)];

        if let Some(type_node) = ty {
            children.push(self.process_node(type_node.0));
        }
        children.push(self.process_node(initializer.0));

        AstOutput::new(if is_mutable { "MutableLet" } else { "Let" }).with_children(children)
    }

    fn process_def_node(
        &self,
        _node_id: NodeId,
        name: NodeId,
        params: NodeId,
        return_ty: Option<NodeId>,
        block: NodeId,
    ) -> AstOutput {
        let mut children = vec![self.process_node(name.0), self.process_node(params.0)];

        if let Some(ret_ty) = return_ty {
            children.push(self.process_node(ret_ty.0));
        }
        children.push(self.process_node(block.0));

        AstOutput::new("Definition").with_children(children)
    }

    fn process_binary_op(&self, _node_id: NodeId, lhs: NodeId, op: NodeId, rhs: NodeId) -> AstOutput {
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

        AstOutput::new("BinaryOp")
            .with_name(op_name)
            .with_children(vec![self.process_node(lhs.0), self.process_node(rhs.0)])
    }

    fn process_list_node(&self, _node_id: NodeId, items: &[NodeId]) -> AstOutput {
        AstOutput::new("List").with_children(items.iter().map(|id| self.process_node(id.0)).collect())
    }

    fn process_block_node(&self, _node_id: NodeId, block_id: BlockId) -> AstOutput {
        let block = &self.compiler.blocks[block_id.0];
        AstOutput::new("Block")
            .with_children(block.nodes.iter().map(|id| self.process_node(id.0)).collect())
    }

    fn process_if_node(
        &self,
        _node_id: NodeId,
        condition: NodeId,
        then_block: NodeId,
        else_block: Option<NodeId>,
    ) -> AstOutput {
        let mut children = vec![self.process_node(condition.0), self.process_node(then_block.0)];

        if let Some(else_node) = else_block {
            children.push(self.process_node(else_node.0));
        }

        AstOutput::new("If").with_children(children)
    }

    fn process_call_node(&self, _node_id: NodeId, parts: &[NodeId]) -> AstOutput {
        AstOutput::new("Call")
            .with_children(parts.iter().map(|id| self.process_node(id.0)).collect())
    }
}
