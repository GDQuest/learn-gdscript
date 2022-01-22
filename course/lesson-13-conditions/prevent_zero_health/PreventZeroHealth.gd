extends Control

var health = 20
var _health_gained = 100
var _max_health = 80

onready var _robot := $HealSprite


func _ready() -> void:
	_robot.health_gained = _health_gained
	_robot.health = health
	_robot.max_health = _max_health
	_robot._update_health_bar()


func _run() -> void:
	take_damage(_health_gained)
	_update_robot()
	yield(get_tree().create_timer(1.0), "timeout")
	Events.emit_signal("practice_run_completed")


func _update_robot() -> void:
	_robot._animation_player.play("damage")
	_robot.health_gained = _health_gained
	_robot.health = health
	_robot.max_health = _max_health
	_robot._update_health_bar()


# EXPORT damage
func take_damage(amount):
	health -= amount
	if health < 0:
		health = 0
# /EXPORT damage
