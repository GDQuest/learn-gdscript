extends Control

# In Godot 4, find_node() is replaced by find_child(). 
# The parameters (pattern, recursive, owner) are usually (name, true, false).
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

# EXPORT create
var inventory = {
	"healing heart": 3,
	"gems": 9,
	"sword": 1,
}
# /EXPORT create

func run() -> void:
	for item in inventory:
		var amount = inventory[item]
		display_item(item, amount)


func _run() -> void:
	clear_drawing()
	run()
	# await is correct for Godot 4
	await get_tree().create_timer(0.5).timeout
	# Signal emission is now done via the signal object itself
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
		# Accessing the Label node and setting text
		instance.get_node("Margin/Item/Amount").text = str(amount)
		instance.show()


func update_display() -> void:
	clear_drawing()
	for item in inventory:
		display_item(item, inventory[item])
