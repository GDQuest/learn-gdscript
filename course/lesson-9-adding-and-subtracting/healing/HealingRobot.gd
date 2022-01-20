extends Control

var health = 50
var _healing = 50
var _max_health = 100

onready var _robot := $RobotCharacter


func _ready() -> void:
	_robot.health = health
	_robot.max_health = _max_health
	_robot._update_health_bar()


func _run() -> void:
	heal(_healing)
	_update_robot()
	yield(get_tree().create_timer(1.0), "timeout")
	Events.emit_signal("practice_run_completed")


func _update_robot() -> void:
	_robot._animation_player.play("heal")
	_robot.health = health
	_robot.max_health = _max_health
	_robot._update_health_bar()


# EXPORT heal
func heal(amount):
	health += amount
# /EXPORT heal
