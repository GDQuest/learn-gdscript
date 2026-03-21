@tool
extends HBoxContainer

@onready var tree := get_tree()


func _ready() -> void:
	resized.connect(update_size)


func update_size() -> void:
	await tree.process_frame
	for control in get_children():
		var new_position: Vector2 = control.position
		var texture_rect: TextureRect = control.get_child(0)
		texture_rect.position.x = - new_position.x
		texture_rect.size = size
