extends Node2D

var _damage = 50
var _max_health = 100

onready var _animation_tree := find_node("AnimationTree")
onready var _health_bar := find_node("CustomHealthBar")


func _ready() -> void:
	yield(get_tree(), "idle_frame")
	_health_bar.set_health(health)


func _run() -> void:
	reset()
	take_damage(_damage)
	_update_robot()
	yield(get_tree().create_timer(1.0), "timeout")
	Events.emit_signal("practice_run_completed")


func _update_robot() -> void:
	_animation_tree.travel("damage")
	_health_bar.set_health(health)


# EXPORT damage
var health = 100

func take_damage(amount):
	health -= amount
# /EXPORT damage


func reset():
	health = 100
	_health_bar.set_health(health)
