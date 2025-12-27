extends Control

# Godot 4: find_node is replaced by find_child
@onready var item_nodes := {
	"healing heart": find_child("HealingHeart", true, false),
	"gems": find_child("Gems", true, false),
	"sword": find_child("Sword", true, false),
}

@onready var _grid := $Margin/Column/Grid as GridContainer


func _ready() -> void:
	reset()


func reset() -> void:
	for node in item_nodes.values():
		if node:
			node.hide()
	
	inventory["healing heart"] = 0
	inventory["gems"] = 0
	inventory["sword"] = 0


var inventory := {
	"healing heart": 0,
	"gems": 0,
	"sword": 0,
}

# EXPORT add
func add_item(item_name: String, amount: int) -> void:
	if inventory.has(item_name):
		inventory[item_name] += amount
# /EXPORT add


func run() -> void:
	for i in range(2):
		add_item("healing heart", 4)
		add_item("gems", 2)
		add_item("sword", 3)
	
	for item in inventory:
		var amount = inventory[item]
		display_item(item, amount)


func _run() -> void:
	clear_drawing()
	run()
	await get_tree().create_timer(0.5).timeout
	# Godot 4 Signal syntax
	Events.practice_run_completed.emit()


func clear_drawing() -> void:
	if _grid:
		for child in _grid.get_children():
			child.hide()
	

func display_item(item: String, amount: int) -> void:
	if not item in item_nodes:
		return

	var instance = item_nodes[item]
	if instance:
		instance.get_node("Margin/Item/Amount").text = str(amount)
		instance.show()


func update_display() -> void:
	clear_drawing()
	for item in inventory:
		display_item(item, inventory[item])
