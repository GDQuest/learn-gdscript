extends Node2D


var level = 3
var health = 100
var max_health = 100

onready var _animation_player := $AnimationPlayer
onready var _health_bar := $HealthBar/HealthBarCurrent as ColorRect
onready var _label := $HealthBar/Label as Label
onready var _tween := $Tween as Tween

# EXPORT damage
func take_damage(amount):
	if level > 2:
		amount *= 0.5
	
	health -= amount

	if health > max_health:
		health = max_health

	if health < 0:
		health = 0
# /EXPORT damage

func _run():
	take_damage(10)
	_update_health_bar()
	_animation_player.play("damage")
	yield(get_tree().create_timer(0.5), "timeout")
	Events.emit_signal("practice_run_completed")


func _update_health_bar() -> void:
	var size_current = _health_bar.rect_size.x
	var size_to = 190.0 * health / max_health
	
	_label.text = "health = %s" % [health]
	
	_tween.interpolate_property(_health_bar, "rect_size:x", size_current, size_to, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	_tween.start()
