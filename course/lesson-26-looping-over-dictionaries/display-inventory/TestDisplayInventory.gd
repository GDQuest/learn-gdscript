extends PracticeTester

var inventory: Node


func _prepare() -> void:
	inventory = _scene_root_viewport.get_child(0)


func test_all_items_are_displayed():
	var displayed: Dictionary = inventory.get_displayed_items_info()
	var source: Dictionary = inventory.get("inventory")
	var inventories_match := displayed.has_all(source.keys())
	if inventories_match:
		for key in displayed:
			if displayed[key] != source[key]:
				inventories_match = false
				break

	if not inventories_match:
		return tr("The displayed items do not match the inventory variable's content. Did you call the display_item() function for each item in the inventory?")

	return ""


func test_code_uses_a_for_loop():
	var run_function := _analyzer.get_function_named("run")
	
	if not GDExpr.suite(
		GDExpr.for_loop(
			GDExpr.any_identifier(),
			GDExpr.identifier("inventory"),
		)
	).matches(run_function):
		return tr("Your code has no for loop. You need to use a for loop to complete this practice, even if there are other solutions!")
	
	return ""
