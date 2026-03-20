extends Control


@onready var item_nodes := {
	"healing heart": find_child("HealingHeart"),
	"gems": find_child("Gems"),
	"sword": find_child("Sword"),
}

@onready var _grid := $Margin/Column/Grid as GridContainer


func _ready() -> void:
	reset()


func reset():
	for node in item_nodes.values():
		node.hide()
	
	inventory["healing heart"] = 0
	inventory["gems"] = 0
	inventory["sword"] = 0


var inventory = {
	"healing heart": 0,
	"gems": 0,
	"sword": 0,
}

# EXPORT add
func add_item(item_name, amount):
	inventory[item_name] += amount
# /EXPORT add


func run():
	for i in range(2):
		add_item("healing heart", 4)
		add_item("gems", 2)
		add_item("sword", 3)
	for item in inventory:
		var amount = inventory[item]
		display_item(item, amount)


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
