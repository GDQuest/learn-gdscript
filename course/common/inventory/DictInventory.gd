class_name DictInventory
extends Control

const DictItemScene := preload("DictItem.tscn")

const ITEM_DATABASE := {
	"healing heart":
	{
		"icon": preload("healing_heart.png"),
		"name": "Healing Heart",
	},
	"sword":
	{
		"icon": preload("sword.png"),
		"name": "Sword",
	},
	"shield":
	{
		"icon": preload("shield.png"),
		"name": "Shield",
	},
	"gems":
	{
		"icon": preload("gems.png"),
		"name": "Gems",
	},
}

var inventory = {
	"healing heart": 3,
	"sword": 1,
	"shield": 1,
	"gems": 10,
}

@onready var _grid := $Margin/Column/Grid as GridContainer


func _ready():
	update_display()


func add_item(name: String, amount := 1):
	assert(name in ITEM_DATABASE)
	if name in inventory:
		inventory[name] += amount
	else:
		inventory[name] = amount
	update_display()


func remove_item(name: String, amount := 1):
	assert(name in ITEM_DATABASE)
	if name in inventory:
		inventory[name] -= amount
		if inventory[name] <= 0:
			inventory.erase(name)
		update_display()
	else:
		printerr("Trying to remove nonexistent item in inventory: " + name)


func update_display():
	for child in _grid.get_children():
		child.queue_free()

	for item in inventory:
		var instance = DictItemScene.instantiate()
		assert(item in ITEM_DATABASE, "The item must exist in the ITEM_DATABASE dictionary.")
		instance.icon = ITEM_DATABASE[item].icon
		instance.item_name = ITEM_DATABASE[item].name
		instance.amount = inventory[item]
		_grid.add_child(instance)
