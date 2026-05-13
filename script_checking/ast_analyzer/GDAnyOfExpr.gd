class_name GDAnyOfExpr
extends GDExpr


var _expressions: Array[GDExpr] = []

func _init(expressions: Array) -> void:
	for expression in expressions:
		assert(expression is GDExpr, "Can only accept GDExpr types")
		_expressions.push_back(expression)


func matches(node: GDNode) -> bool:
	return _expressions.any(func(expression: GDExpr) -> bool: return expression.matches(node))
