@tool
extends HBoxContainer

func _ready() -> void:
	resized.connect(update_size)
	update_size()


func update_size() -> void:
	if not is_inside_tree():
		return
		
	await get_tree().process_frame
	
	for child in get_children():
		var control := child as Control
		if not control:
			continue
			
		var new_position: Vector2 = control.position
		
		if control.get_child_count() > 0:
			var texture_rect := control.get_child(0) as TextureRect
			if texture_rect:
				texture_rect.position.x = -new_position.x
				texture_rect.size = size
