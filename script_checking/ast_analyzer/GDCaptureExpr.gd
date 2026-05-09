class_name GDCaptureExpr
extends GDIdentifierExpr


func _init(name: StringName, captures: Dictionary) -> void:
	_name = name
	_captures = captures


func matches(node: GDNode) -> bool:
	if node.get_type() != GDNode.IDENTIFIER:
		return false
	var ident_node := node as GDIdentifierNode
	return ident_node.name == _captures[_name]
