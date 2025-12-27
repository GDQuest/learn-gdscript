extends PracticeTester

var inventory: Node

var desired_inventory := {
	"healing heart": 3,
	"gems": 9,
	"sword": 1,
}

func _prepare() -> void:
	inventory = _scene_root_viewport.get_child(0)

func test_inventory_has_correct_keys() -> String:
	var source_raw = inventory.get("inventory")
	if not source_raw is Dictionary:
		return tr("The 'inventory' variable is missing or is not a Dictionary.")
	
	var source: Dictionary = source_raw

	if source.size() != desired_inventory.size():
		return (
			tr("The amount of items is not as expected. The inventory should have %s items but your inventory has %s.")
			% [desired_inventory.size(), source.size()] 
			+ " " + tr("Are you missing any items?")
		)

	# In Godot 4, we check if all keys in our desired dict exist in the source keys
	var inventories_match: bool = desired_inventory.keys().all(func(key): return source.has(key))
	
	if inventories_match:
		return ""

	# PoolStringArray -> PackedStringArray
	var keys_string := "', '".join(PackedStringArray(desired_inventory.keys()))
	return tr(
		"The inventory doesn't contain all the required items. Make sure you have '%s' as keys in your inventory dictionary."
	) % keys_string


func test_inventory_has_correct_values() -> String:
	var source_raw = inventory.get("inventory")
	if not source_raw is Dictionary:
		return tr("The 'inventory' variable is missing or is not a Dictionary.")
		
	var source: Dictionary = source_raw
	
	var inventory_keys_do_match := (
		desired_inventory.size() == source.size() and
		desired_inventory.keys().all(func(key): return source.has(key))
	)
	
	var inventory_values_do_match := true
	if inventory_keys_do_match:
		for key in source.keys():
			if not desired_inventory[key] == source[key]:
				inventory_values_do_match = false
				break
	else:
		var keys_string := "', '".join(PackedStringArray(desired_inventory.keys()))
		return tr(
			"The inventory doesn't contain all the required items. Make sure you have '%s' as keys in your inventory dictionary."
		) % keys_string

	if not inventory_values_do_match:
		return tr(
			"The values for one or more items aren't correct. You need %s healing hearts, %s gems, and %s sword."
		) % [desired_inventory["healing heart"], desired_inventory["gems"], desired_inventory["sword"]]

	return ""
