class_name DictInventory
extends Control

const DictItemScene := preload("DictItem.tscn")

const ITEM_DATABASE := {
	"healing heart": {
		"icon": preload("healing_heart.png"),
		"name": "Healing Heart",
	},
	"sword": {
		"icon": preload("sword.png"),
		"name": "Sword",
	},
	"shield": {
		"icon": preload("shield.png"),
		"name": "Shield",
	},
	"gems": {
		"icon": preload("gems.png"),
		"name": "Gems",
	},
}

@export var _grid: GridContainer

var inventory = {
	"healing heart": 3,
	"sword": 1,
	"shield": 1,
	"gems": 10,
}


func _ready():
	update_display()


func add_item(item_name: String, amount := 1):
	assert(item_name in ITEM_DATABASE)
	if item_name in inventory:
		inventory[item_name] += amount
	else:
		inventory[item_name] = amount
	update_display()


func remove_item(item_name: String, amount := 1):
	assert(item_name in ITEM_DATABASE)
	if item_name in inventory:
		inventory[item_name] -= amount
		if inventory[item_name] <= 0:
			inventory.erase(item_name)
		update_display()
	else:
		printerr("Trying to remove nonexistent item in inventory: " + item_name)


func update_display():
	for child in _grid.get_children():
		child.queue_free()

	for item in inventory:
		var instance: DictItem = DictItemScene.instantiate()
		assert(item in ITEM_DATABASE, "The item must exist in the ITEM_DATABASE dictionary.")
		instance.icon = ITEM_DATABASE[item].icon
		instance.item_name = ITEM_DATABASE[item].name
		instance.amount = inventory[item]
		_grid.add_child(instance)
