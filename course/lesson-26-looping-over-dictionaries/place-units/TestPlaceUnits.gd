extends PracticeTester

var grid: Node


func _prepare() -> void:
	grid = _scene_root_viewport.get_child(0)


func test_all_units_are_displayed():
	var displayed: Dictionary = grid.get_displayed_units_info()
	var source: Dictionary = grid.get("units")
	var dicts_match := displayed.has_all(source.keys())
	if dicts_match:
		for key in displayed:
			if displayed[key] != source[key]:
				dicts_match = false
				break

	if not dicts_match:
		return tr("The displayed units do not match the units variable's content. Did you call the place_unit() function for each unit in the units dictionary?")
	return ""


func test_code_uses_a_for_loop():
	var run_function := _analyzer.get_function_named("run")
	
	if not GDExpr.suite(
		GDExpr.for_loop(
			GDExpr.any_identifier(),
			GDExpr.identifier("units")
		)
	).matches(run_function):
		return tr("Your code has no for loop. You need to use a for loop to complete this practice, even if there are other solutions!")
	return ""
