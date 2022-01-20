extends Node2D


func _ready() -> void:
	set_process(false)

# EXPORT clarify
var angular_speed = 4

func _process(delta):
	rotate(angular_speed * delta)

func set_angular_speed(new_angular_speed):
	angular_speed = new_angular_speed
# /EXPORT clarify


func _run() -> void:
	reset()
	_process(0.0)
	set_process(true)


func reset() -> void:
	rotation = 0.0
	position = Vector2(300, 200)
	set_process(false)
