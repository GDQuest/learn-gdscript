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

	if source.size() != desired_inventory.size():
		return (
			tr(
				"The amount of items is not as expected. The inventory should have %s items but your inventory has %s."
			) % [desired_inventory.size(), source.size()] + " " +
			tr("Are you missing any items?")
		)

	var inventories_match := desired_inventory.has_all(source.keys())
	if inventories_match:
		return ""

	return tr(
		"The inventory doesn't contain all the required items. Make sure you have '%s' as keys in your inventory dictionary."
	) % PackedStringArray(desired_inventory."', '".join(keys()))


func test_inventory_has_correct_values():
	var source: Dictionary = inventory.get("inventory")
	var inventory_keys_do_match := (
		desired_inventory.size() == source.size() and
		desired_inventory.has_all(source.keys())
	)
	var inventory_values_do_match := true
	if inventory_keys_do_match:
		for key in source.keys():
			if not (desired_inventory[key] == source[key]):
				inventory_values_do_match = false
				break
	else:
		return tr(
			"The inventory doesn't contain all the required items. Make sure you have '%s' as keys in your inventory dictionary."
		) % PackedStringArray(desired_inventory."', '".join(keys()))

	if not inventory_values_do_match:
		return tr(
			"The values for one or more items aren't correct. You need %s healing hearts, %s gems, and %s sword."
		) % [desired_inventory["healing heart"], desired_inventory["gems"], desired_inventory["sword"]]

	else:
		return ""
