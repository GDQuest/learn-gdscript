extends PracticeTester

var inventory: Node


func _prepare() -> void:
	inventory = _scene_root_viewport.get_child(0)


func test_all_items_are_displayed():
	var displayed: Dictionary = inventory.get_displayed_items_info()
	var source: Dictionary = inventory.get("inventory")
	var inventories_match := displayed.has_all(source.keys())
	if inventories_match:
		for value in displayed.values():
			if not source.values().has(value):
				inventories_match = false
				break

	if not inventories_match:
		return tr(
			"The displayed items do not match the inventory variable's content. Did you call the display_item() function for each item in the inventory?"
		)

	return ""


func test_code_uses_a_for_loop():
	var loops_over_inventory := false
	for line in _slice.current_text.split("\n"):
		if "for" in line and "inventory" in line:
			loops_over_inventory = true
			break

	if not loops_over_inventory:
		return tr(
			"Your code has no for loop. You need to use a for loop to complete this practice, even if there are other solutions!"
		)
	return ""
