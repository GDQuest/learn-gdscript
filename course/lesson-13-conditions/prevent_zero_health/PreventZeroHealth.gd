extends Control

var health = 20
var _health_lost = 10
var _max_health = 80

var _produced_health_values = []

onready var _robot := find_node("Robot")
onready var _animation_tree := find_node("AnimationTree")
onready var _health_bar := find_node("CustomHealthBar")


func _ready() -> void:
	_health_bar.max_health = _max_health
	_health_bar.set_health(health)


func _run() -> void:
	_produced_health_values.clear()
	take_damage(_health_lost)
	_produced_health_values.append(health)
	take_damage(_health_lost)
	_produced_health_values.append(health)
	take_damage(_health_lost)
	_produced_health_values.append(health)
	_update_robot()
	yield(get_tree().create_timer(1.0), "timeout")
	Events.emit_signal("practice_run_completed")


func _update_robot() -> void:
	_animation_tree.travel("damage")
	_health_bar.set_health(health)


# EXPORT damage
func take_damage(amount):
	health -= amount
	if health < 0:
		health = 0
# /EXPORT damage

func get_produced_health_values() -> Array:
	return _produced_health_values
