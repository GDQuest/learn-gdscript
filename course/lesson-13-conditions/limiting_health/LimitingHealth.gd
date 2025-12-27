extends CenterContainer

var health := 20
var _health_gained := 40
var _max_health := 80

var _produced_health_values := []

@onready var _animation_tree := find_child("AnimationTree") as AnimationTree
@onready var _health_bar := find_child("CustomHealthBar") as Node


func _ready() -> void:
	# Use set() and call() to access custom properties/methods on nodes found via find_child
	_health_bar.set("max_health", _max_health)
	_health_bar.call("set_health", health)


func _run() -> void:
	reset()
	heal(_health_gained)
	_produced_health_values.append(health)
	heal(_health_gained)
	_produced_health_values.append(health)
	_update_robot()
	await get_tree().create_timer(1.0).timeout
	# Godot 4 signal syntax
	Events.practice_run_completed.emit()


func _update_robot() -> void:
	var playback := _animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	if playback:
		playback.travel("heal")
	
	_health_bar.call("set_health", health)


# EXPORT heal
func heal(amount: int) -> void:
	health += amount
	if health > 80:
		health = 80
# /EXPORT heal

func get_produced_health_values() -> Array:
	return _produced_health_values


func reset() -> void:
	health = 20
	_health_bar.call("set_health", health)
	_produced_health_values.clear()
