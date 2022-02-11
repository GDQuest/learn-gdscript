extends Node2D

var health := 100
var turtle_power = 20

onready var _health_bar := find_node("CustomHealthBar")
onready var _animation_player := $AnimationPlayer


func _ready():
	health = 100
	_health_bar.set_health(health)


# EXPORT battle
func battle():
	while health > 0:
		health -= turtle_power
# /EXPORT battle
		_animation_player.play("fight")
		yield(_animation_player, "animation_finished")
		_health_bar.set_health(health)

func _run():
	battle()
	Events.emit_signal("practice_run_completed")
