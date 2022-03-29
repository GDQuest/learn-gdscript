tool
extends HBoxContainer

onready var tree := get_tree()


func _ready() -> void:
	connect("resized", self, "update_size")


func update_size() -> void:
	yield(tree, "idle_frame")
	for control in get_children():
		var new_position: Vector2 = control.rect_position
		var texture_rect: TextureRect = control.get_child(0)
		texture_rect.rect_position.x = - new_position.x
		texture_rect.rect_size = rect_size
