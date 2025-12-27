class_name DictInventory
extends Control

const DictItemScene: PackedScene = preload("res://course/common/inventory/DictItem.tscn")


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


func add_item(item_id: String, amount := 1):
	assert(item_id in ITEM_DATABASE)
	if item_id in inventory:
		inventory[item_id] += amount
	else:
		inventory[item_id] = amount
	update_display()

func remove_item(item_id: String, amount := 1):
	assert(item_id in ITEM_DATABASE)
	if item_id in inventory:
		inventory[item_id] -= amount
		if inventory[item_id] <= 0:
			inventory.erase(item_id)
		update_display()
	else:
		printerr("Trying to remove nonexistent item in inventory: " + item_id)


func update_display():
	for child in _grid.get_children():
		child.queue_free()

	for item in inventory:
		var instance := DictItemScene.instantiate() as DictItem
		instance.icon = ITEM_DATABASE[item].icon
		instance.item_name = ITEM_DATABASE[item].name
		instance.amount = inventory[item]
		_grid.add_child(instance)
