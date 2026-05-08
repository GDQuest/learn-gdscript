## Expressions that are used to match against the parser's nodes
## e.g.
## [codeblock]
## var process := _analyzer.get_function_named("_process")
## if not GDExpr.suite(
## 		GDExpr.function_call(
## 			"rotate",
## 			GDExpr.multiply(
## 				GDExpr.literal(2.0),
## 				GDExpr.identifier(process_delta_name)
## 			)
## 		)
## 	).matches(process):
## 		return tr("The rotation speed is not right. The robot should rotate 2 radians per second. Make sure the call looks like this: rotate(2 * delta).")
## [/codeblock]
@abstract
class_name GDExpr
extends RefCounted


## Will return true if the expression and any sub-expression it depends on match against a GDNode and its children
@abstract
func matches(node: GDNode) -> bool


## Creates an expression that will match a GDNode to a binary op node that uses OP_MULITPLICATION between
## its two operands. If strict is true, the order matters as left, right, otherwise either will do
static func multiply(operand_a: GDExpr, operand_b: GDExpr, strict: bool = false) -> GDBinaryOpExpr:
	return bin_op(operand_a, operand_b, GDBinaryOpNode.OP_MULTIPLICATION, strict)


## Creates an expression that will match a GDNode to a binary op node of operation type between
## its two operands. If strict is true, the order matters as left, right, otherwise either will do.
static func bin_op(operand_a: GDExpr, operand_b: GDExpr, operation: GDBinaryOpNode.OpType, strict: bool = true) -> GDBinaryOpExpr:
	var new_expr := GDBinaryOpExpr.new(operand_a, operand_b, operation, strict)
	return new_expr


## Creates an expression that will match a GDNode to an identifier by name
## Make regex true to match using a regex string
static func identifier(name: String, as_regex := false) -> GDIdentifierExpr:
	var new_expr := GDIdentifierExpr.new(name, as_regex)
	return new_expr


## Creates an expresion that will match any GDIdentifierNode
static func any_identifier() -> GDIdentifierExpr:
	return GDIdentifierExpr.new(".*", true)


## Creates an expression that will match a GDNode to a literal.
## If approx_equal is true, will use is_equal_approx, otherwise ==
## If ignore_value is true, will match with any literal node
static func literal(value: Variant, approx_equal: bool = false, ignore_value: bool = false) -> GDLiteralExpr:
	var new_expr := GDLiteralExpr.new(value, approx_equal, ignore_value)
	return new_expr


## Creates an expression that will match a GDNode to an assignment
static func assignment(assignee: GDExpr, assignment_expr: GDExpr, operation: GDAssignmentNode.Operation = GDAssignmentNode.Operation.OP_NONE) -> GDAssignExpr:
	var new_expr := GDAssignExpr.new(assignee, assignment_expr, operation)
	return new_expr


## Creates an expression that will match a GDIfNode and its contents
## Providing either true/false blocks is optional, if you're only checking the condition
static func if_block(condition: GDExpr, truth_block: GDExpr = null, false_block: GDExpr = null) -> GDIfExpr:
	var new_expr := GDIfExpr.new(condition, truth_block, false_block)
	return new_expr


## Creates an expression that will match any GDNode that contains a single GDSuiteNode
static func suite(...statements) -> GDSuiteExpr:
	var new_expr := GDSuiteExpr.new(statements as Array)
	return new_expr


## Creates an expression that will always match to any node
static func any() -> GDAnyExpr:
	return GDAnyExpr.new()


## Creates an expression that will match one or more of the provided expressions
static func any_of(...expressions) -> GDAnyOfExpr:
	return GDAnyOfExpr.new(expressions as Array)


## Creates an expression that will match a function by its name and arguments
## Any arguments that you do not want to match should be null
static func function_call(name: StringName, ...arguments) -> GDCallExpr:
	var typed_arguments: Array[GDExpr] = []
	for argument in arguments:
		typed_arguments.push_back(argument)
	var new_expr := GDCallExpr.new(name, typed_arguments)
	return new_expr


static func for_loop(loop_variable: GDIdentifierExpr = null, list: GDExpr = null, body: GDSuiteExpr = null) -> GDForExpr:
	return GDForExpr.new(loop_variable, list, body)


static func captured_identifier(name: StringName, captures: Dictionary) -> GDCaptureExpr:
	return GDCaptureExpr.new(name, captures)


static func array(elements: Array) -> GDArrayExpr:
	var new_elements: Array[GDExpr] = []
	for element in elements:
		assert(element is GDExpr, "Can only accept GDExpr elements")
		new_elements.push_back(element)
	return GDArrayExpr.new(new_elements)


class GDArrayExpr extends GDExpr:
	var _elements: Array[GDExpr]
	
	
	func _init(elements: Array[GDExpr]) -> void:
		_elements = elements
	

	func matches(node: GDNode) -> bool:
		if node.get_type() != GDNode.ARRAY:
			return false
		var array_node := node as GDArrayNode
		var elements := array_node.get_elements()
		if elements.size() < _elements.size():
			return false
		for i in _elements.size():
			if not _elements[i].matches(elements[i]):
				return false
		return true


class GDCaptureExpr extends GDIdentifierExpr:
	func _init(name: StringName, captures: Dictionary) -> void:
		_name = name
		_captures = captures
	
	
	func matches(node: GDNode) -> bool:
		if node.get_type() != GDNode.IDENTIFIER:
			return false
		var ident_node := node as GDIdentifierNode
		return ident_node.name == _captures[_name]


class GDForExpr extends GDExpr:
	var _loop_variable: GDExpr
	var _body: GDExpr
	var _list: GDExpr
	
	func _init(loop_variable: GDIdentifierExpr = null, list: GDExpr = null, body: GDSuiteExpr = null) -> void:
		_loop_variable = loop_variable
		_body = body
		_list = list
	
	
	func matches(node: GDNode) -> bool:
		if node.get_type() != GDNode.FOR:
			return false
		var for_node := node as GDForNode
		if (
			(_loop_variable and not _loop_variable.matches(for_node.get_variable())) or
			(_list and not _list.matches(for_node.get_list())) or
			(_body and not _body.matches(for_node.get_loop()))
		):
			return false
		return true


class GDAnyOfExpr extends GDExpr:
	var _expressions: Array[GDExpr] = []
	
	func _init(expressions: Array) -> void:
		for expression in expressions:
			assert(expression is GDExpr, "Can only accept GDExpr types")
			_expressions.push_back(expression)
	
	
	func matches(node: GDNode) -> bool:
		return _expressions.any(func(expression: GDExpr) -> bool: return expression.matches(node))


class GDSuiteExpr extends GDExpr:
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


class GDIfExpr extends GDExpr:
	var _condition: GDExpr
	var _truth_block: GDExpr
	var _false_block: GDExpr
	
	func _init(condition: GDExpr, truth_block: GDExpr = null, false_block: GDExpr = null) -> void:
		_condition = condition
		_truth_block = truth_block
		_false_block = false_block
	
	
	func matches(node: GDNode) -> bool:
		if node.get_type() != GDNode.IF:
			return false
		var if_node := node as GDIfNode
		
		return (
			_condition.matches(if_node.get_condition()) and
			(not _truth_block or _truth_block.matches(if_node.get_true_block())) and
			(not _false_block or _false_block.matches(if_node.get_false_block()))
		)


class GDAssignExpr extends GDExpr:
	var _assignee: GDExpr
	var _operation: GDAssignmentNode.Operation
	var _assignment_expr: GDExpr
	
	func _init(assignee: GDExpr, assignment_expr: GDExpr, operation: GDAssignmentNode.Operation) -> void:
		_assignee = assignee
		_assignment_expr = assignment_expr
		_operation = operation


	func matches(node: GDNode) -> bool:
		if node.get_type() != GDNode.ASSIGNMENT:
			return false
		var assignment_node := node as GDAssignmentNode
		return assignment_node.get_operation() == _operation and _assignee.matches(assignment_node.get_assignee()) and _assignment_expr.matches(assignment_node.get_assigned_value())



class GDAnyExpr extends GDExpr:
	func matches(_node: GDNode) -> bool:
		return true


class GDCallExpr extends GDExpr:
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


class GDLiteralExpr extends GDExpr:
	var _value: Variant
	var _any_value := false
	var _approx := false


	func _init(value: Variant, approx: bool, any_value: bool) -> void:
		_value = value
		_any_value = any_value
		_approx = approx


	func matches(node: GDNode) -> bool:
		if node.get_type() != GDNode.LITERAL:
			return false
		if _any_value:
			return true
		var lit_node := node as GDLiteralNode
		if _approx:
			if _value is float and lit_node.get_value() is float:
				return is_equal_approx(lit_node.value as float, _value as float)
			elif _value is AABB and lit_node.get_value() is AABB:
				return (_value as AABB).is_equal_approx(lit_node.get_value() as AABB)
			elif _value is Basis and lit_node.get_value() is Basis:
				return (_value as Basis).is_equal_approx(lit_node.get_value() as Basis)
			elif _value is Color and lit_node.get_value() is Color:
				return (_value as Color).is_equal_approx(lit_node.get_value() as Color)
			elif _value is Plane and lit_node.get_value() is Plane:
				return (_value as Plane).is_equal_approx(lit_node.get_value() as Plane)
			elif _value is Quaternion and lit_node.get_value() is Quaternion:
				return (_value as Quaternion).is_equal_approx(lit_node.get_value() as Quaternion)
			elif _value is Rect2 and lit_node.get_value() is Rect2:
				return (_value as Rect2).is_equal_approx(lit_node.get_value() as Rect2)
			elif _value is Transform2D and lit_node.get_value() is Transform2D:
				return (_value as Transform2D).is_equal_approx(lit_node.get_value() as Transform2D)
			elif _value is Transform3D and lit_node.get_value() is Transform3D:
				return (_value as Transform3D).is_equal_approx(lit_node.get_value() as Transform3D)
			elif _value is Vector2 and lit_node.get_value() is Vector2:
				return (_value as Vector2).is_equal_approx(lit_node.get_value() as Vector2)
			elif _value is Vector3 and lit_node.get_value() is Vector3:
				return (_value as Vector3).is_equal_approx(lit_node.get_value() as Vector3)
			elif _value is Vector4 and lit_node.get_value() is Vector4:
				return (_value as Vector4).is_equal_approx(lit_node.get_value() as Vector4)
		var value: Variant = lit_node.value
		return value == _value


class GDIdentifierExpr extends GDExpr:
	var _name: String
	var _regex: RegEx = null
	var _do_capture := false
	var _capture_name: StringName
	var _captures: Dictionary

	func _init(name: String, use_regex: bool) -> void:
		_name = name
		if use_regex:
			_regex = RegEx.create_from_string(name)


	func matches(node: GDNode) -> bool:
		if node.get_type() != GDNode.IDENTIFIER:
			return false
		
		var ident_node := node as GDIdentifierNode
		var does_match := false
		if _regex:
			does_match = _regex.search(ident_node.name) != null
		else:
			does_match = ident_node.name == _name
		if _do_capture:
			_captures[_capture_name] = ident_node.name
		return does_match


	func capture(name: StringName, captures: Dictionary) -> GDIdentifierExpr:
		_capture_name = name
		_captures = captures
		_captures[_capture_name] = &""
		_do_capture = true
		return self


class GDBinaryOpExpr extends GDExpr:
	var _operands: Array[GDExpr] = []
	var _strict_order := false
	var _type: GDBinaryOpNode.OpType
	
	func _init(operand_a: GDExpr, operand_b: GDExpr, type: GDBinaryOpNode.OpType, strict_order: bool) -> void:
		_operands = [operand_a, operand_b]
		_strict_order = strict_order
		_type = type


	func matches(node: GDNode) -> bool:
		if node.get_type() != GDNode.BINARY_OPERATOR:
			return false
		var binary_op := node as GDBinaryOpNode
		if binary_op.operation != _type:
			return false
		var does_match := _operands[0].matches(binary_op.left) and _operands[1].matches(binary_op.right)
		if not does_match and not _strict_order:
			does_match = _operands[1].matches(binary_op.left) and _operands[0].matches(binary_op.right)
		return does_match
