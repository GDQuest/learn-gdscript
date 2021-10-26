extends Node2D

var _obstacles := []


func _ready() -> void:
	seed(0)
	for child in get_children():
		if child.is_in_group("obstacles"):
			_obstacles.push_back(child)
			remove_child(child)


# EXPORT get_random
func get_random_obstacle() -> Node:
	var size := _obstacles.size()
	var index := randi() % size
	# warning-ignore:unsafe_cast
	var obstacle = _obstacles[index]
	return obstacle


# /EXPORT get_random


func dispense() -> Node:
	var model := get_random_obstacle()
	var obstacle: Node = model.duplicate(DUPLICATE_SCRIPTS | DUPLICATE_GROUPS)
	# warning-ignore:unsafe_property_access
	# warning-ignore:unsafe_property_access
	obstacle.texture = model.texture
	# warning-ignore:unsafe_property_access
	# warning-ignore:unsafe_property_access
	obstacle.shape = model.shape
	# warning-ignore:unsafe_property_access
	obstacle.visible = true
	add_child(obstacle)
	return obstacle
