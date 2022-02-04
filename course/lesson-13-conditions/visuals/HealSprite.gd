extends Node2D

export var health := 100
export var max_health := 100
export var health_gained := 25


onready var _animation_player := $AnimationPlayer as AnimationPlayer

onready var start_health = health

func _ready() -> void:
	
	pass


func run() -> void:
	if _tween.is_active():
		return
	
	_heal()
	_animation_player.stop(true)
	_animation_player.play("heal")
	_update_health_bar()


func reset() -> void:
	health = start_health
	_update_health_bar()





# Virtual method
func _heal() -> void:
	pass
