class_name GDBinaryOpExpr
extends GDExpr


var _operands: Array[GDExpr] = []
var _strict_order := false
var _type: GDBinaryOpNode.OpType

func _init(operand_a: GDExpr, operand_b: GDExpr, type: GDBinaryOpNode.OpType, strict_order: bool) -> void:
	_operands = [operand_a, operand_b]
	_strict_order = strict_order
	_type = type


func matches(node: GDNode) -> bool:
	if node.get_type() != GDNode.BINARY_OPERATOR:
		return false
	var binary_op := node as GDBinaryOpNode
	if binary_op.operation != _type:
		return false
	var does_match := _operands[0].matches(binary_op.left) and _operands[1].matches(binary_op.right)
	if not does_match and not _strict_order:
		does_match = _operands[1].matches(binary_op.left) and _operands[0].matches(binary_op.right)
	return does_match
