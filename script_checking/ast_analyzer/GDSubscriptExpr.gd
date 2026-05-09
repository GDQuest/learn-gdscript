class_name GDSubscriptExpr
extends GDExpr


var _index: GDExpr
var _base: GDExpr

func _init(base: GDExpr, index: GDExpr) -> void:
	_index = index
	_base = base


func matches(node: GDNode) -> bool:
	if node.get_type() != GDNode.SUBSCRIPT:
		return false
	var subscript_node := node as GDSubscriptNode
	
	return _index.matches(subscript_node.get_as_index()) and _base.matches(subscript_node.get_base())
