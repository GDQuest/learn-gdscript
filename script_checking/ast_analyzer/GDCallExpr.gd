class_name GDCallExpr
extends GDExpr


var _name: StringName
var _arguments: Array[GDExpr]

func _init(name: StringName, arguments: Array[GDExpr]) -> void:
	_name = name
	_arguments = arguments


func matches(node: GDNode) -> bool:
	if node.get_type() != GDNode.CALL:
		return false
	var call_node := node as GDCallNode
	if call_node.get_function_name() != _name:
		return false
	var call_arguments := call_node.get_arguments()
	if call_arguments.size() < _arguments.size():
		return false
	for i in _arguments.size():
		var argument: GDExpr = _arguments[i]
		if argument == null:
			continue
		if not argument.matches(call_arguments[i]):
			return false
	return call_node.get_function_name() == _name
