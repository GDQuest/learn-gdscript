class_name GDAssignExpr
extends GDExpr


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
