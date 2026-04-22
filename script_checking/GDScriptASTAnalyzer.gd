class_name GDScriptASTAnalyzer
extends GDScriptLocalAnalyzer


var _student_class: GDClassNode


func _init(student_class: GDClassNode) -> void:
	_student_class = student_class


func find_any_recursive_function() -> String:
	var functions: Array[GDFunctionNode] = []
	for member: GDMember in _student_class.get_members():
		if member.get_type() != GDMember.FUNCTION:
			continue
		functions.push_back(member.get_as_function_node())
	for function in functions:
		var function_name := function.get_identifier().get_name()
		var statements := function.get_body().get_statements()
		for statement in statements:
			if statement.get_type() == GDNode.CALL:
				var call_node := statement as GDCallNode
				if call_node.get_function_name() == function_name:
					return function_name
	return ""


func has_infinite_while_loop() -> bool:
	var functions: Array[GDFunctionNode] = []
	for member: GDMember in _student_class.get_members():
		if member.get_type() != GDMember.FUNCTION:
			continue
		functions.push_back(member.get_as_function_node())
	for function in functions:
		if _check_body_for_infinite_while(function.get_body()):
			return true
	return false


func _check_body_for_infinite_while(suite: GDSuiteNode) -> bool:
	var statements := suite.get_statements()
	for statement in statements:
		match statement.get_type():
			GDNode.FOR:
				var for_statement := statement as GDForNode
				if _check_body_for_infinite_while(for_statement.get_loop()):
					return true
			GDNode.FUNCTION:
				var function_statement := statement as GDFunctionNode
				if _check_body_for_infinite_while(function_statement.get_body()):
					return true
			GDNode.IF:
				var if_statement := statement as GDIfNode
				var false_block := if_statement.get_false_block()
				if (
					_check_body_for_infinite_while(if_statement.get_true_block()) or
					(false_block and _check_body_for_infinite_while(false_block))
				):
					return true
			GDNode.MATCH:
				var match_statement := statement as GDMatchNode
				for branch in match_statement.get_branches():
					if _check_body_for_infinite_while(branch.get_block()):
						return true
			GDNode.WHILE:
				var while_statement := statement as GDWhileNode
				if _is_while_loop_infinite(while_statement):
					return true
				if _check_body_for_infinite_while(while_statement.get_loop()):
					return true
			GDNode.LAMBDA:
				var lambda_statement := statement as GDLambdaNode
				if _check_body_for_infinite_while(lambda_statement.get_function().get_body()):
					return true
			GDNode.VARIABLE:
				var variable_statement := statement as GDVariableNode
				var initializer := variable_statement.get_initializer()
				if initializer.get_type() == GDNode.LAMBDA:
					var lambda_assignment := initializer as GDLambdaNode
					if _check_body_for_infinite_while(lambda_assignment.get_function().get_body()):
						return true
	return false


func _is_while_loop_infinite(loop: GDWhileNode) -> bool:
	if _has_break_statement(loop.get_loop()):
		return false
	
	var condition := loop.get_condition()
	var literal_condition := condition as GDLiteralNode
	# true, 1, -1.2
	if literal_condition:
		var value: Variant = literal_condition.get_reduced_value()
		if (
			(value is bool and value == true) or
			(value is int and value != 0) or
			(value is float and value != 0.0)
		):
			return true
	
	# 'not false', 'not 0', !false
	var unary_condition := condition as GDUnaryOpNode
	if unary_condition and unary_condition.get_operation() == GDUnaryOpNode.OP_LOGIC_NOT:
		var operand := unary_condition.get_operand()
		literal_condition = operand as GDLiteralNode
		if literal_condition:
			var value: Variant = literal_condition.get_reduced_value()
			if (
				(value is bool and value == false) or
				(value is int and value == 0) or
				(value is float and value == 0.0)
			):
				return true
	
	# math that amounts to non zero
	var binary_op_condition := condition as GDBinaryOpNode
	if binary_op_condition:
		if binary_op_condition.get_left_operand() is GDLiteralNode and binary_op_condition.get_right_operand() is GDLiteralNode:
			var value: Variant = binary_op_condition.get_reduced_value()
			if (
				(value is bool and value == true) or
				(value is int and value != 0) or
				(value is float and value != 0.0)
			):
				return true
	
	# TODO: ultimately we aren't catching function calls that will always return true
	
	return false


func _has_break_statement(body: GDSuiteNode) -> bool:
	for statement in body.get_statements():
		match statement.get_type():
			GDNode.BREAK:
				return true
			GDNode.IF:
				var if_statement := statement as GDIfNode
				if (
					_has_break_statement(if_statement.get_true_block()) or
					_has_break_statement(if_statement.get_false_block())
				):
					return true
			GDNode.MATCH:
				var match_statement := statement as GDMatchNode
				for branch in match_statement.get_branches():
					if _has_break_statement(branch.get_block()):
						return true
			# other suites include for/while loops (break will only break the nested loop)
			# lambdas and variables with lambdas (break would be breaking a loop inside)
			_:
				pass
	return false
