class_name GDFunctionExpr
extends GDExpr


var _name: StringName
var _body: GDSuiteExpr
var _parameters: Array[GDParameterExpr]


func _init(name: StringName, parameters: Array, body: GDSuiteExpr = null) -> void:
	_name = name
	_parameters = []
	for function_parameter in parameters:
		assert(function_parameter is GDParameterExpr, "Can only accept GDParameterExpr")
		_parameters.push_back(function_parameter)
	_body = body


func matches(node: GDNode) -> bool:
	if node.get_type() != GDNode.FUNCTION:
		return false
	var function_node := node as GDFunctionNode
	if function_node.get_identifier().name != _name:
		return false
	var local_parameters := function_node.get_parameters()
	if local_parameters.size() < _parameters.size():
		return false
	for i in _parameters.size():
		var function_parameter := _parameters[i]
		if not function_parameter:
			continue
		if not function_parameter.matches(local_parameters[i]):
			return false
	if _body and not _body.matches(function_node.get_body()):
		return false
	return true
