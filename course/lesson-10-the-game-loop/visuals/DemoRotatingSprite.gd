extends Node2D


func _ready():
	set_process(false)


func run():
	set_process(true)


func _process(delta : float) -> void:
	rotate(0.05)
