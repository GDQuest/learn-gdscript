extends PracticeTester

var inventory: Node

var desired_inventory := {
	"healing heart": 3,
	"gems": 9,
	"sword": 1,
}

func _prepare() -> void:
	inventory = _scene_root_viewport.get_child(0)


func test_inventory_has_correct_keys():
	var source: Dictionary = inventory.get("inventory")
	var inventories_match := source.has_all(desired_inventory.keys())
	if inventories_match:
		return ""

	return tr(
		"The item names aren't correct. Are you missing any?"
	)

	return ""


func test_inventory_has_correct_values():
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
