class_name GDSuiteExpr
extends GDExpr


var _statements: Array[GDExpr] = []

func _init(statements: Array) -> void:
	for statement: GDExpr in statements:
		assert(statement, "Can only accept GDExpr arguments")
		_statements.push_back(statement)


func matches(node: GDNode) -> bool:
	var suite_node: GDSuiteNode = null
	if node.get_type() == GDNode.FUNCTION:
		suite_node = (node as GDFunctionNode).get_body()
	elif node.get_type() == GDNode.SUITE:
		suite_node = node as GDSuiteNode
	else:
		return false
	
	var suite_statements := suite_node.get_statements()
	
	for statement_expression: GDExpr in _statements:
		var found_match := false
		for suite_statement: GDNode in suite_statements:
			if statement_expression.matches(suite_statement):
				found_match = true
				break
		if not found_match:
			return false
	return true
