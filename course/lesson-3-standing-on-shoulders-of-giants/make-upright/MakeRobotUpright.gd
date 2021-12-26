extends Node2D

onready var start_rotation := rotation

func _run():
	rotation = start_rotation
	# EXPORT rotate
	rotate(0.5)
	# /EXPORT rotate
