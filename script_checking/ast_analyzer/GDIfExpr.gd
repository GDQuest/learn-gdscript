class_name GDIfExpr
extends GDExpr


var _condition: GDExpr
var _truth_block: GDExpr
var _false_block: GDExpr

func _init(condition: GDExpr, truth_block: GDExpr = null, false_block: GDExpr = null) -> void:
	_condition = condition
	_truth_block = truth_block
	_false_block = false_block


func matches(node: GDNode) -> bool:
	if node.get_type() != GDNode.IF:
		return false
	var if_node := node as GDIfNode
	
	return (
		_condition.matches(if_node.get_condition()) and
		(not _truth_block or _truth_block.matches(if_node.get_true_block())) and
		(not _false_block or _false_block.matches(if_node.get_false_block()))
	)
