extends Control

onready var tween := $Tween as Tween

func _ready() -> void:
	var index := 1
	for item in get_children():
		item.index = index
		index += 1


func use_item(index: int) -> void:
	if index < 0:
		index += get_child_count()
	if index > get_child_count() - 1:
		printerr("Trying to access nonexistent item in inventory.")
		return
	
	get_child(index).use()
