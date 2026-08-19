extends PracticeTester

var inventory: Node


func _prepare() -> void:
	inventory = _scene_root_viewport.get_child(0)


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("All Items Are Displayed"), tr(""), test_all_items_are_displayed))
	checks.append(Check.new(tr("Code Uses A For Loop"), tr(""), test_code_uses_a_for_loop))


func test_all_items_are_displayed():
	var displayed: Dictionary = inventory.get_displayed_items_info()
	var source: Dictionary = inventory.get("inventory")
	if displayed.size() != source.size():
		return tr("The number of items displayed does not match the number of items in the inventory. Did you display each item exactly once?")

	var inventories_match := displayed.has_all(source.keys())
	if inventories_match:
		for key in source:
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
			null,
			null,
			GDExpr.suite(GDExpr.function_call("display_item")),
		)
	).matches(run_function):
		return tr("Your code does not use a for loop to call display_item(). Please make sure you display each item inside the loop.")

	return ""
