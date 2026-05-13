class_name GDParameterExpr
extends GDExpr


var _identifier: GDIdentifierExpr
var _initializer: GDExpr

func _init(parameter_identifier: GDIdentifierExpr, initializer: GDExpr = null) -> void:
	_identifier = parameter_identifier
	_initializer  = initializer


func matches(node: GDNode) -> bool:
	if node.get_type() != GDNode.PARAMETER:
		return false
	var parameter_node := node as GDParameterNode
	if not _identifier.matches(parameter_node.get_identifier()):
		return false
	if _initializer and not _initializer.matches(parameter_node.get_initializer()):
		return false
	return true
