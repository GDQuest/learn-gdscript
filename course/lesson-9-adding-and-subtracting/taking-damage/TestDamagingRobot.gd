extends PracticeTester

var first_node: Node2D
var health := 0


func _prepare() -> void:
	first_node = _scene_root_viewport.get_child(0)
	health = first_node.health


func test_robot_takes_the_right_amount_of_damage() -> String:
	if health > 100:
		return tr("The health goes above 100 when we damage the robot. Did you subract amount from health?")
	
	if not health == 50:
		return tr("The robot didn't take as much damage as expected. It has %s health, but it should have 50 health after taking damage.") % [health]
	
	return ""

func test_subtract_amount_from_health() -> String:
	var take_damage_function := _analyzer.get_function_named("take_damage")
	if not take_damage_function:
		return tr("It looks like the take_damage function is missing; did you remove it?")
	
	var damage_parameter := _analyzer.get_function_parameter_name(take_damage_function, 0)
	
	if not GDExpr.suite(
		GDExpr.any_of(
			GDExpr.assignment(
				GDExpr.identifier("health"),
				GDExpr.identifier(damage_parameter),
				GDAssignmentNode.Operation.OP_SUBTRACTION
			),
			GDExpr.assignment(
				GDExpr.identifier("health"),
				GDExpr.bin_op(
					GDExpr.identifier("health"),
					GDExpr.identifier(damage_parameter),
					GDBinaryOpNode.OP_SUBTRACTION,
					true
				)
			)
		)
	).matches(take_damage_function):
		return tr("It doesn't look like you're subtracting amount from health.")
	
	return ""
