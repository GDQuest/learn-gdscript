extends PracticeTester

var robot: Node2D


func _prepare() -> void:
	robot = _scene_root_viewport.get_child(0).get_node("Robot")

func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("Character Is Rotating Clockwise"), tr(""), test_character_is_rotating_clockwise))


func test_character_is_rotating_clockwise() -> String:
	var process := _analyzer.get_function_named("_process")

	if not process or not GDExpr.suite(GDExpr.function_call("rotate", null)).matches(process):
		return tr("Did you use rotate() to make the sprite rotate?")

	for statement in process.get_body().get_statements():
		if statement.get_type() != GDNode.CALL:
			continue
		var call := statement as GDCallNode
		if call.get_function_name() != "rotate" or call.get_arguments().is_empty():
			continue
		var argument := call.get_arguments()[0] as GDLiteralNode
		if not argument:
			continue
		var value: Variant = argument.get_reduced_value()
		if (value is int or value is float) and value < 0.0:
			return tr("The robot is turning in the wrong direction!")

	if robot.rotation < 0.0:
		return tr("The robot is turning in the wrong direction!")
	return ""
