class_name GDForExpr
extends GDExpr


var _loop_variable: GDExpr
var _body: GDExpr
var _list: GDExpr

func _init(loop_variable: GDIdentifierExpr = null, list: GDExpr = null, body: GDSuiteExpr = null) -> void:
	_loop_variable = loop_variable
	_body = body
	_list = list


func matches(node: GDNode) -> bool:
	if node.get_type() != GDNode.FOR:
		return false
	var for_node := node as GDForNode
	if (
		(_loop_variable and not _loop_variable.matches(for_node.get_variable())) or
		(_list and not _list.matches(for_node.get_list())) or
		(_body and not _body.matches(for_node.get_loop()))
	):
		return false
	return true
