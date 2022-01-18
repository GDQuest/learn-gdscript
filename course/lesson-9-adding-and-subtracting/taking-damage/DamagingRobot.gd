extends Control

var health = 20
var _health_gained = -50
var _max_health = 100

onready var _robot := $RobotCharacter


func _ready() -> void:
	if not _robot:
		return
	_robot.health_gained = _health_gained
	_robot.health = health
	_robot.max_health = _max_health
	_robot._update_health_bar()


func _run() -> void:
	take_damage(_health_gained)
	_update_robot()


func _update_robot() -> void:
	_robot._animation_player.play("damage")
	_robot.health_gained = _health_gained
	_robot.health = health
	_robot.max_health = _max_health
	_robot._update_health_bar()


# EXPORT damage
func take_damage(amount):
	health -= amount
# /EXPORT damage
