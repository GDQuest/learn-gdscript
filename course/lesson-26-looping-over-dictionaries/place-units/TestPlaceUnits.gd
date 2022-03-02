extends PracticeTester

var grid: Node


func _prepare() -> void:
	grid = _scene_root_viewport.get_child(0)


func test_all_items_are_displayed():
	var displayed: Dictionary = grid.get_displayed_units_info()
	var source: Dictionary = grid.get("units")
	var dicts_match := displayed.has_all(source.keys())
	if dicts_match:
		for value in displayed.values():
			if not source.values().has(value):
				dicts_match = false
				break

	if not dicts_match:
		return tr(
			"The displayed units do not match the units variable's content. Did you call the place_unit() function for each unit in the units dictionary?"
		)

	return ""


func test_code_uses_a_for_loop():
	var loops_over_inventory := false
	for line in _slice.current_text.split("\n"):
		if "for" in line and "units" in line:
			loops_over_inventory = true
			break

	if not loops_over_inventory:
		return tr(
			"Your code has no for loop. You need to use a for loop to complete this practice, even if there are other solutions!"
		)
	return ""
