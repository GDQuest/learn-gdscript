## Expressions that are used to match against the parser's nodes
## e.g.
## [codeblock]
## var captures := {}
## # func _process(delta):
## if not GDExpr.function(
## 	"_process",
## 	GDExpr.suite(
## 		# rotate(2.0 * delta)
## 		GDExpr.function_call(
## 			"rotate",
## 			GDExpr.multiply(
## 				GDExpr.literal(2.0),
## 				GDExpr.captured_identifier("delta", captures)
## 			)
## 		)
## 	),
## 	GDExpr.parameter(
## 		# capture delta to be used with captured_identifier()
## 		GDExpr.any_identifier().capture("delta", captures)
## 	)
## ).matches(process):
## 	return tr("The rotation speed is not right. The robot should rotate 2 radians per second. Make sure the call looks like this: rotate(2 * %s)." % [captures.delta])
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
## Accepts one of:[br]
## - SUITE: Directly access suite[br]
## - FUNCTION: A function's body[br]
## - FOR: The loop's body[br]
## - WHILE: The loop's body[br]
## - IDENTIFIER: The suite the identifier is part of[br]
## - IF: The true block[br]
## - MATCH_BRANCH: The block for the branch[br]
## The order the statements appear is not importance, so long as they appear.
## If the order matters, use [method strict_suite].
static func suite(...statements) -> GDSuiteExpr:
	var new_expr := GDSuiteExpr.new(statements as Array, false)
	return new_expr


## As [method suite], but every statement is guaranteed to be positioned relative to the expressions' order.
static func strict_suite(...statements) -> GDSuiteExpr:
	var new_expr := GDSuiteExpr.new(statements as Array, true)
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


## Creates an expression that will match against a for loop by any or all of its var, list, and suite
static func for_loop(loop_variable: GDIdentifierExpr = null, list: GDExpr = null, body: GDSuiteExpr = null) -> GDForExpr:
	return GDForExpr.new(loop_variable, list, body)


## Creates an expression that will match against an identifier that was previously captured
## See GDIdentifierExpr.capture()
static func captured_identifier(name: StringName, captures: Dictionary) -> GDCaptureExpr:
	return GDCaptureExpr.new(name, captures)


## Creates an expression that will match against an array literal and any of its elements
static func array(elements: Array) -> GDArrayExpr:
	var new_elements: Array[GDExpr] = []
	for element in elements:
		assert(element is GDExpr, "Can only accept GDExpr elements")
		new_elements.push_back(element)
	return GDArrayExpr.new(new_elements)


## Creates an expression that will match against an array or dictionary subscript access
## E.g. my_array[6]
static func subscript(base: GDExpr, index: GDExpr) -> GDSubscriptExpr:
	return GDSubscriptExpr.new(base, index)


## Creates an expression that will match against a function by its name, body and parameters
## Pass in null for any parameter you do not want to check against
static func function(name: StringName, body: GDSuiteExpr = null, ...parameters) -> GDFunctionExpr:
	return GDFunctionExpr.new(name, parameters as Array, body)


## Creates an expression that will match against a parameter by its name and optionally its default value
static func parameter(parameter_identifier: GDIdentifierExpr, initializer: GDExpr = null) -> GDParameterExpr:
	return GDParameterExpr.new(parameter_identifier, initializer)
