extends PracticeTester

var inventory: Node

var desired_inventory := {
	"healing heart": 8,
	"gems": 4,
	"sword": 6,
}

func _prepare() -> void:
	inventory = _scene_root_viewport.get_child(0)


func test_add_item_function_works_as_intended():
	var source: Dictionary = inventory.get("inventory")
	var inventories_match := source.has_all(desired_inventory.keys())
	if inventories_match:
		for key in source.keys():
			if not desired_inventory[key] == source[key]:
				inventories_match = false
				break

	if not inventories_match:
		return tr(
			"The amount of items isn't correct. Does each key have the correct value?"
		)

	return ""


func test_add_item_function_uses_addition() -> String:
	var regex = RegEx.new()
	regex.compile("inventory.*\\+")
	var result = regex.search(_slice.current_text)
	if not result:
		return tr("It doesn't look like you're adding amount to the value in the inventory dictionary.")
	return ""
