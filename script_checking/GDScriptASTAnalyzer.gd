class_name GDScriptASTAnalyzer
extends GDScriptLocalAnalyzer

var root: GDClassNode


## This data structure contains the result of analyzing GDScript code's AST.
class AstAnalysisResult:
	## The line numbers of the start of each loop in the script.
	var lines_loop_start: Array[int] = []
	## If true, the code contains an infinite loop.
	var has_infinite_loop := false


func _init(student_class: GDClassNode) -> void:
	root = student_class


func get_function_named(name: StringName) -> GDFunctionNode:
	if root.has_function(name):
		return root.get_member(name).get_as_function_node()
	return null


func get_var_named(name: StringName) -> GDVariableNode:
	if root.has_member(name):
		var member := root.get_member(name)
		if member.get_type() == GDNode.VARIABLE:
			return member.get_as_signal_variable_node()
	return null


func get_function_parameter_name(function: GDFunctionNode, index: int) -> StringName:
	if index >= function.get_parameters().size():
		return &""
	return function.get_parameters()[index].get_identifier().name


func get_statement_assignment(
	function_node: GDFunctionNode,
	assignee: StringName,
	starting_from_index := 0,
) -> GDAssignmentNode:
	var statements := function_node.get_body().get_statements()
	for i: int in range(starting_from_index, statements.size()):
		var assign_statement: GDAssignmentNode = statements[i] as GDAssignmentNode
		if assign_statement:
			var assignee_node := assign_statement.get_assignee() as GDIdentifierNode
			if assignee_node and assignee_node.name == assignee:
				return assign_statement
	return null


func get_statement_call_named(
	function_node: GDFunctionNode,
	name: StringName,
	starting_from_index := 0,
) -> GDCallNode:
	var statements := function_node.get_body().get_statements()
	for i: int in range(starting_from_index, statements.size()):
		var call_statement: GDCallNode = statements[i] as GDCallNode
		if call_statement and call_statement.get_function_name() == name:
			return call_statement
	return null


func get_local_var_named(
	function_node: GDFunctionNode,
	name: StringName,
	starting_from_index := 0,
) -> GDVariableNode:
	var statements := function_node.get_body().get_statements()
	for i: int in range(starting_from_index, statements.size()):
		var var_statement := statements[i] as GDVariableNode
		if var_statement and var_statement.get_identifier().name == name:
			return var_statement
	return null


func find_any_recursive_function() -> String:
	var functions: Array[GDFunctionNode] = []
	for member: GDMember in root.get_members():
		if member.get_type() != GDMember.FUNCTION:
			continue
		functions.push_back(member.get_as_function_node())
	for function in functions:
		var function_name := function.get_identifier().get_name()
		var statements := function.get_body().get_statements()
		for statement in statements:
			if _does_expression_contain_recursive_call(statement, function_name):
				return function_name
	return ""


## Recursively checks if an expression contains a recursive call to the given function.
func _does_expression_contain_recursive_call(expression: GDNode, function_name: StringName) -> bool:
	if expression == null:
		return false

	match expression.get_type():
		GDNode.CALL:
			var call_node := expression as GDCallNode
			if not call_node.is_super() and call_node.get_function_name() == function_name:
				return true
			for argument in call_node.get_arguments():
				if _does_expression_contain_recursive_call(argument, function_name):
					return true
		GDNode.ASSIGNMENT:
			return _does_expression_contain_recursive_call(
				(expression as GDAssignmentNode).get_assigned_value(),
				function_name,
			)
		GDNode.VARIABLE:
			return _does_expression_contain_recursive_call(
				(expression as GDVariableNode).get_initializer(),
				function_name,
			)
		GDNode.BINARY_OPERATOR:
			var binary_operator := expression as GDBinaryOpNode
			return (
				_does_expression_contain_recursive_call(
					binary_operator.get_left_operand(),
					function_name,
				)
				or _does_expression_contain_recursive_call(
					binary_operator.get_right_operand(),
					function_name,
				)
			)
		GDNode.UNARY_OPERATOR:
			return _does_expression_contain_recursive_call(
				(expression as GDUnaryOpNode).get_operand(),
				function_name,
			)
	return false


## Analyzes the AST of the script and returns an [code]AstAnalysisResult[/code]
## structure.
func analyze_ast() -> AstAnalysisResult:
	var analysis := AstAnalysisResult.new()
	for member: GDMember in root.get_members():
		if member.get_type() == GDMember.FUNCTION:
			var function := member.get_as_function_node()
			_visit_ast_recursively(function.get_body(), function, analysis)
	return analysis


# Visitor that probes through the GDScript AST recursively.
func _visit_ast_recursively(
	suite: GDSuiteNode,
	function: GDFunctionNode,
	analysis: AstAnalysisResult,
) -> void:
	for statement in suite.get_statements():
		match statement.get_type():
			GDNode.FOR:
				var for_statement := statement as GDForNode
				analysis.lines_loop_start.append(for_statement.get_start_line())
				var iterated_container := for_statement.get_list() as GDIdentifierNode
				if (
					iterated_container
					and _loop_body_appends_to_container(
						for_statement.get_loop(),
						iterated_container.name,
					)
				):
					analysis.has_infinite_loop = true
				_visit_ast_recursively(for_statement.get_loop(), function, analysis)
			GDNode.WHILE:
				var while_statement := statement as GDWhileNode
				analysis.lines_loop_start.append(while_statement.get_start_line())
				if _is_while_loop_infinite(while_statement):
					analysis.has_infinite_loop = true
				else:
					var condition := while_statement.get_condition() as GDIdentifierNode
					if (
						condition and _is_container_name(function, condition.name)
						and _loop_body_appends_to_container(
							while_statement.get_loop(),
							condition.name,
						)
					):
						analysis.has_infinite_loop = true
				_visit_ast_recursively(while_statement.get_loop(), function, analysis)
			GDNode.FUNCTION:
				var function_statement := statement as GDFunctionNode
				_visit_ast_recursively(function_statement.get_body(), function_statement, analysis)
			GDNode.IF:
				var if_statement := statement as GDIfNode
				_visit_ast_recursively(if_statement.get_true_block(), function, analysis)
				if if_statement.get_false_block():
					_visit_ast_recursively(if_statement.get_false_block(), function, analysis)
			GDNode.MATCH:
				var match_statement := statement as GDMatchNode
				for branch in match_statement.get_branches():
					_visit_ast_recursively(branch.get_block(), function, analysis)
			GDNode.LAMBDA:
				var lambda_statement := statement as GDLambdaNode
				var lambda_function := lambda_statement.get_function()
				_visit_ast_recursively(lambda_function.get_body(), lambda_function, analysis)
			GDNode.VARIABLE:
				var variable_statement := statement as GDVariableNode
				var initializer := variable_statement.get_initializer()
				if initializer and initializer.get_type() == GDNode.LAMBDA:
					var lambda_assignment := initializer as GDLambdaNode
					var assigned_lambda_function := lambda_assignment.get_function()
					_visit_ast_recursively(
						assigned_lambda_function.get_body(),
						assigned_lambda_function,
						analysis,
					)


func _is_while_loop_infinite(loop: GDWhileNode) -> bool:
	if _has_break_statement(loop.get_loop()):
		return false

	var condition := loop.get_condition()
	var literal_condition := condition as GDLiteralNode
	# true, 1, -1.2
	if literal_condition:
		var value: Variant = literal_condition.get_reduced_value()
		if (
			(value is bool and value == true) or (value is int and value != 0)
			or (value is float and value != 0.0)
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
				(value is bool and value == false) or (value is int and value == 0)
				or (value is float and value == 0.0)
			):
				return true

	# math that amounts to non zero
	var binary_op_condition := condition as GDBinaryOpNode
	if binary_op_condition:
		if (
			binary_op_condition.get_left_operand() is GDLiteralNode
			and binary_op_condition.get_right_operand() is GDLiteralNode
		):
			var value: Variant = binary_op_condition.get_reduced_value()
			if (
				(value is bool and value == true) or (value is int and value != 0)
				or (value is float and value != 0.0)
			):
				return true

	# TODO: ultimately we aren't catching function calls that will always return true
	return false


## Returns true if the function declares a container variable with the given name.
func _is_container_name(function: GDFunctionNode, name: StringName) -> bool:
	# Only inspect variables initialized as arrays or dictionaries.
	if root.has_member(name):
		var member := root.get_member(name)
		if member.get_type() == GDMember.VARIABLE:
			var member_variable := member.get_as_signal_variable_node()
			if _is_container_variable(member_variable):
				return true
	for statement in function.get_body().get_statements():
		if statement.get_type() == GDNode.VARIABLE:
			var variable := statement as GDVariableNode
			if (variable.get_identifier().name == name and _is_container_variable(variable)):
				return true
	return false


func _is_container_variable(variable: GDVariableNode) -> bool:
	var initializer := variable.get_initializer()
	return initializer is GDArrayNode or initializer is GDDictionaryNode


func _loop_body_appends_to_container(body: GDSuiteNode, container_name: StringName) -> bool:
	# Catch appending values to a container while iterating over it.
	for statement in body.get_statements():
		if statement.get_type() == GDNode.CALL:
			var gd_call := statement as GDCallNode
			var callee := gd_call.get_callee() as GDSubscriptNode
			var base := callee.get_base() as GDIdentifierNode if callee else null
			if (
				base and base.name == container_name
				and gd_call.get_function_name() in [&"append", &"push_back", &"push_front"]
			):
				return true
	return false


func _has_break_statement(body: GDSuiteNode) -> bool:
	for statement in body.get_statements():
		match statement.get_type():
			GDNode.BREAK:
				return true
			GDNode.IF:
				var if_statement := statement as GDIfNode
				if (
					_has_break_statement(if_statement.get_true_block())
					or _has_break_statement(if_statement.get_false_block())
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
