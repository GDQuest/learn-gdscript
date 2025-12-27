extends Node2D

@onready var _animation_tree := find_child("AnimationTree")
@onready var _health_bar := find_child("CustomHealthBar") as ColorRect

# EXPORT damage
var level = 3
var health = 100
var max_health = 100

func take_damage(amount):
	if level > 2:
		amount *= 0.5
	
	health -= amount

	if health < 0:
		health = 0
# /EXPORT damage

func _run():
	reset()
	take_damage(10)
	_health_bar.set_health(health)
	_animation_tree.travel("damage")
	await get_tree().create_timer(0.5).timeout
	Events.emit_signal("practice_run_completed")


func reset():
	level = 3
	health = 100
	max_health = 100
	_health_bar.set_health(health)
