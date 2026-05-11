class_name GDSuiteExpr
extends GDExpr


var _statements: Array[GDExpr] = []
var _strict_order: bool


func _init(statements: Array, strict_order: bool) -> void:
	_strict_order = strict_order
	
	for statement: GDExpr in statements:
		assert(statement, "Can only accept GDExpr arguments")
		_statements.push_back(statement)


func matches(node: GDNode) -> bool:
	var suite_node: GDSuiteNode = null
	match node.get_type():
		GDNode.SUITE:
			suite_node = node as GDSuiteNode
		GDNode.FUNCTION:
			suite_node = (node as GDFunctionNode).get_body()
		GDNode.FOR:
			suite_node = (node as GDForNode).get_loop()
		GDNode.WHILE:
			suite_node = (node as GDWhileNode).get_loop()
		GDNode.IDENTIFIER:
			suite_node = (node as GDIdentifierNode).get_suite()
		GDNode.IF:
			suite_node = (node as GDIfNode).get_true_block()
		GDNode.MATCH_BRANCH:
			suite_node = (node as GDMatchBranchNode).get_block()
		_:
			return false
	
	var suite_statements := suite_node.get_statements()
	var indices := []
	
	for statement_expression: GDExpr in _statements:
		var found_match := false
		for i in suite_statements.size():
			var suite_statement: GDNode = suite_statements[i]
			if statement_expression.matches(suite_statement):
				indices.push_back(i)
				found_match = true
				break
		if not found_match:
			return false
	if _strict_order:
		var previous: int = indices[0]
		for i in range(1, indices.size()):
			if indices[i] < previous:
				return false
	return true
