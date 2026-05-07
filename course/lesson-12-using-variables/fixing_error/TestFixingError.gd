extends PracticeTester

var robot: Node2D
var has_angular_speed_prop := false
var _checker: GDScriptErrorChecker
var _analyzer: GDScriptASTAnalyzer


func _prepare():
	robot = _scene_root_viewport.get_child(0)
	has_angular_speed_prop = false
	for property in robot.get_property_list():
		if property.name == "angular_speed":
			has_angular_speed_prop = true
			break
	_checker = GDScriptErrorChecker.new()
	_checker.set_source(_slice.current_text)
	var root := _checker.get_root_parse_node()
	_analyzer = GDScriptASTAnalyzer.new(root)


func test_has_angular_speed_variable() -> String:
	if not has_angular_speed_prop:
		return tr("The angular_speed variable doesn't exist. Did you define it with the var keyword?")
	return ""


func test_angular_speed_has_value_of_4() -> String:
	if not has_angular_speed_prop:
		return tr("The angular speed variable doesn't exist, can't test if it has a value of 4.")
	var angular_speed_value = robot.get("angular_speed")
	if angular_speed_value == 4:
		return ""
	return tr("Angular speed variable's value is %s; It should be 4.") % angular_speed_value


func test_angular_speed_is_used_in_process_function() -> String:
	var process := _analyzer.get_function_named("_process")
	if not process:
		return tr("The '_process(delta)' function is missing; did you remove it?")
	
	var rotate_call := _analyzer.get_statement_call_named(process, "rotate")
	if not rotate_call:
		return tr("Did you use rotate() to make the sprite rotate?")
	
	var process_delta_name := _analyzer.get_function_parameter_name(process, 0)
	
	if not GDExpr.function_call("rotate", GDExpr.multiply(GDExpr.identifier("angular_speed"), GDExpr.identifier(process_delta_name))).matches(rotate_call):
		return tr("The rotate() call must multiply angular_speed by delta (e.g. rotate(angular_speed * delta)).")
	
	return ""


func test_each_function_uses_the_same_variable() -> String:
	var process := _analyzer.get_function_named("_process")
	if not process:
		return tr("The '_process(delta)' function is missing; did you remove it?")
	
	var local := _analyzer.get_local_var_named(process, "angular_speed")
	if local:
		return tr("It looks like you declared angular_speed more than once. It should only be defined once.")
	return ""


func test_angular_speed_is_used_in_setter_function() -> String:
	var setter := _analyzer.get_function_named("set_angular_speed")
	if not setter:
		return tr("The 'set_angular_speed(new_angular_speed)' function is missing; did you remove it?")
	
	var assignment_call := _analyzer.get_statement_assignment(setter, "angular_speed")
	
	if not assignment_call or not GDExpr.assignment(GDExpr.identifier("angular_speed"), GDExpr.identifier("new_angular_speed")).matches(assignment_call):
		return tr("The set_angular_speed() function doesn't seem to use the angular_speed variable.")
	
	return ""
