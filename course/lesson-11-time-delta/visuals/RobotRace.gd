extends Node2D

var computer_speed := 0.1 setget _set_computer_speed, get_computer_speed

onready var _robots := $Robots

func run():
	for child in _robots.get_children():
		child.run()


func _set_computer_speed(new_computer_speed: float):
	computer_speed = new_computer_speed * 10
	
	if not _robots:
		return
	
	for child in _robots.get_children():
		child.computer_speed = computer_speed
		child.reset()


func get_computer_speed():
	return computer_speed
