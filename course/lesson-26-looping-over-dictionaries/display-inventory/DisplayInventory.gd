extends Control


@onready var item_nodes := {
	"healing heart": $Margin/Column/Grid/HealingHeart,
	"gems": $Margin/Column/Grid/Gems,
	"sword": $Margin/Column/Grid/Sword,
}

@onready var _grid := $Margin/Column/Grid as GridContainer

func _ready() -> void:
	for node in item_nodes.values():
		node.hide()


func reset():
	for node in item_nodes.values():
		node.hide()

# EXPORT run
var inventory = {
	"healing heart": 3,
	"gems": 5,
	"sword": 1,
}

func run():
	for item_name in inventory:
		var item_count = inventory[item_name]
		display_item(item_name, item_count)
# /EXPORT run


func _run():
	clear_drawing()
	run()
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")


func clear_drawing():
	for child in _grid.get_children():
		child.hide()


func display_item(item: String, amount: int):
	if not item in item_nodes:
		return

	var instance = item_nodes[item]
	instance.get_node("Margin/Item/Amount").text = str(amount)
	instance.show()


func update_display():
	clear_drawing()
	for item in inventory:
		display_item(item, inventory[item])


# Returns a dict to compare with `inventory` to test the practice.
func get_displayed_items_info() -> Dictionary:
	var out := {}
	for child in _grid.get_children():
		if not child.visible:
			continue
		var item_name = child.get_node("Margin/Item/Name").text.to_lower()
		var amount = int(child.get_node("Margin/Item/Amount").text)
		out[item_name] = amount
	return out
