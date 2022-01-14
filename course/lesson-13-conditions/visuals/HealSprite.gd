extends Node2D

export var health := 100
export var max_health := 100
export var health_gained := 25

onready var _health_bar := $HealthBar/HealthBarCurrent
onready var _label := $HealthBar/Label
onready var _tween := $Tween
onready var _animation_player := $AnimationPlayer


func _ready() -> void:
	_health_bar.rect_size.x = health * 2
	_update_health_bar()


func run() -> void:
	if _tween.is_active():
		return
	
	_heal()
	_animation_player.stop(true)
	_animation_player.play("heal")
	_update_health_bar()


func reset() -> void:
	health = 1
	_update_health_bar()


func _update_health_bar() -> void:
	var size_current = _health_bar.rect_size.x
	var size_to = 190 * health / max_health
	
	_label.text = "health = %s" % [health]
	
	_tween.interpolate_property(_health_bar, "rect_size:x", size_current, size_to, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	_tween.start()


# Virtual method
func _heal() -> void:
	pass
