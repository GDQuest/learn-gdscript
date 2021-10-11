# Obstacle
tool
extends Area2D

signal reached_destination

export (Array, Texture) var images: Array = [] setget set_images

onready var sprite := $Sprite as Sprite
onready var tween := $Tween as Tween


func _ready() -> void:
	_assign_random_texture()


func _assign_random_texture() -> void:
	sprite.texture = images[randi() % images.size()]


func set_destination(position_x: float, time := 4.0) -> void:
	tween.interpolate_property(self, "position:x", position.x, position_x, time)
	tween.start()


func set_images(new_images: Array) -> void:
	images = new_images
	if Engine.editor_hint:
		if not is_inside_tree():
			yield(self, "ready")
		_assign_random_texture()


func _on_Tween_tween_all_completed() -> void:
	emit_signal("reached_destination")
	queue_free()
