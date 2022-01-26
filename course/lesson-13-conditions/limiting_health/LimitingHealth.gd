extends Control

var health = 20
var _health_gained = 40
var _max_health = 80

var _produced_health_values = []

onready var _robot := $HealSprite


func _ready() -> void:
	_robot.health_gained = _health_gained
	_robot.health = health
	_robot.max_health = _max_health
	_robot._update_health_bar()


func _run() -> void:
	_produced_health_values.clear()
	heal(_health_gained)
	_produced_health_values.append(health)
	heal(_health_gained)
	_produced_health_values.append(health)
	_update_robot()
	yield(get_tree().create_timer(1.0), "timeout")
	Events.emit_signal("practice_run_completed")


func _update_robot() -> void:
	_robot._animation_player.play("heal")
	_robot.health_gained = _health_gained
	_robot.health = health
	_robot.max_health = _max_health
	_robot._update_health_bar()


# EXPORT heal
func heal(amount):
	health += amount
	if health > 80:
		health = 80
# /EXPORT heal

func get_produced_health_values() -> Array:
	return _produced_health_values
