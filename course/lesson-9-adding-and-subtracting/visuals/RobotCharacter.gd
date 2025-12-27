extends Node2D

@export var health := 100
@export var max_health := 100

var _start_health := 0

@onready var _empty_health_bar := $HealthBar/HealthBarEmpty as ColorRect
@onready var _health_bar := $HealthBar/HealthBarCurrent as ColorRect
@onready var _label := $HealthBar/Label as Label
# NOTE: AnimationPlayer was used in the Godot 3 version for animation hooks.
# After the Godot 4 port, this script no longer drives animations directly,
# so the reference was removed.
# @onready var _animation_player := $AnimationPlayer as AnimationPlayer
var _tween: Tween


func _ready() -> void:
	_start_health = health
	_health_bar.size.x = _empty_health_bar.size.x * float(health) / float(max_health)
	_update_health_bar()


func run() -> void:
	if _tween:
		return
	
	_run()
	_update_health_bar()


func reset() -> void:
	health = _start_health
	_update_health_bar()


func _update_health_bar() -> void:
	var size_to: float = _empty_health_bar.size.x * float(health) / float(max_health)

	_label.text = "health = %s" % [health]

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_health_bar, "size:x", size_to, 0.2)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)


# Virtual method
func _run() -> void:
	pass
