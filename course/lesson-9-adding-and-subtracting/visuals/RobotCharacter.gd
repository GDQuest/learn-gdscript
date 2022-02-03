extends Node2D

export var health := 100
export var max_health := 100

var _start_health := 0

onready var _empty_health_bar := $HealthBar/HealthBarEmpty as ColorRect
onready var _health_bar := $HealthBar/HealthBarCurrent as ColorRect
onready var _label := $HealthBar/Label as Label
onready var _tween := $Tween as Tween
onready var _animation_player := $AnimationPlayer as AnimationPlayer


func _ready() -> void:
	_start_health = health
	_health_bar.rect_size.x = _empty_health_bar.rect_size.x * health / max_health
	_update_health_bar()


func run() -> void:
	if _tween.is_active():
		return
	
	_run()
	_update_health_bar()


func reset() -> void:
	health = _start_health
	_update_health_bar()


func _update_health_bar() -> void:
	var size_current = _health_bar.rect_size.x
	var size_to = _empty_health_bar.rect_size.x * health / max_health
	
	_label.text = "health = %s" % [health]
	
	_tween.interpolate_property(_health_bar, "rect_size:x", size_current, size_to, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	_tween.start()


# Virtual method
func _run() -> void:
	pass
