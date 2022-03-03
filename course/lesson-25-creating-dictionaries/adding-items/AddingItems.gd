extends Control


onready var item_nodes := {
	"healing heart": $Margin/Column/Grid/HealingHeart,
	"fire gem": $Margin/Column/Grid/FireGem,
	"ice gem": $Margin/Column/Grid/IceGem,
}

onready var _grid := $Margin/Column/Grid as GridContainer


func _ready() -> void:
	for item in inventory:
		var amount = inventory[item]
		display_item(item, amount)


var inventory := {
	"healing heart": 3,
	"fire gem": 2,
	"ice gem": 1,
}

# EXPORT add
func add_item(item_name, amount):
	inventory[item_name] += amount
# /EXPORT add


func run():
	pass


func _run():
	clear_drawing()
	run()
	yield(get_tree().create_timer(0.5), "timeout")
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
