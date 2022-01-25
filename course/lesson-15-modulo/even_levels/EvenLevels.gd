extends Node2D

export var health := 100
export var max_health := 100

var level := 1

onready var _health_bar := $HealthBar/HealthBarCurrent as ColorRect
onready var _label := $HealthBar/Label as Label
onready var _label_level := $LabelLevel as Label
onready var _tween := $Tween as Tween
onready var _animation_player := $AnimationPlayer as AnimationPlayer


func _run():
	
	for i in range(3):
		level_up()
		_update_health_bar()
		_animation_player.play("level")
		yield(_animation_player, "animation_finished")
	
	Events.emit_signal("practice_run_completed")
	
# EXPORT even_level
func level_up():
	level += 1
	max_health += 5
	if level % 2 == 0:
		max_health += 5
# /EXPORT even_level


func _update_health_bar() -> void:
	var size_current = _health_bar.rect_size.x
	var size_to = 190.0 * health / max_health
	
	_label.text = "%s/%s" % [health, max_health]
	_label_level.text = "Level %s" % [level]
	_tween.interpolate_property(_health_bar, "rect_size:x", size_current, size_to, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	_tween.start()
