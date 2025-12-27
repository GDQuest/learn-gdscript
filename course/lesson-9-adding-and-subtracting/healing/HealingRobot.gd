extends Node2D

var _healing := 50

@onready var _animation_tree := find_child("AnimationTree") as AnimationTree
@onready var _health_bar := find_child("CustomHealthBar") as Node


func _ready() -> void:
	await get_tree().process_frame
	if _health_bar.has_method("set_health"):
		_health_bar.call("set_health", health)


func _run() -> void:
	reset()
	heal(_healing)
	_update_robot()
	await get_tree().create_timer(1.0).timeout
	# Godot 4 signal syntax
	Events.practice_run_completed.emit()


func _update_robot() -> void:
	var playback := _animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	if playback:
		playback.travel("heal")
	
	if _health_bar.has_method("set_health"):
		_health_bar.call("set_health", health)


# EXPORT heal
var health := 50

func heal(amount: int) -> void:
	health += amount
# /EXPORT heal


func reset() -> void:
	health = 50
	if _health_bar.has_method("set_health"):
		_health_bar.call("set_health", health)
