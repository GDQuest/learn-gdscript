class_name WrappingNode2D
extends Node2D

var _bounds := Rect2()
var _sprites: Array[CanvasItem] = []

func calculate_bounding_rect(sprites: Array[CanvasItem]) -> Rect2:
	if sprites.is_empty():
		return Rect2()

	var bounds := Rect2()
	for item: CanvasItem in sprites:
		var node := item as Node2D
		if not node:
			continue
			
		var sprite_rect := Rect2()
		if node.has_method("get_rect"):
			sprite_rect = node.call("get_rect")
		
		sprite_rect.position += node.position
		bounds = bounds.merge(sprite_rect)

	bounds.position += position
	return bounds

func wrap_inside_frame(frame_bounds: Rect2) -> void:
	if frame_bounds.encloses(_bounds):
		return

	if _bounds.position.x < frame_bounds.position.x - frame_bounds.size.x / 2.0:
		position.x = frame_bounds.size.x - _bounds.size.x / 2.0
	elif _bounds.position.x + _bounds.size.x > frame_bounds.position.x + frame_bounds.size.x / 2.0:
		position.x = frame_bounds.position.x + _bounds.size.x / 2.0

	if _bounds.position.y < frame_bounds.position.y - frame_bounds.size.y / 2.0:
		position.y = frame_bounds.size.y - _bounds.size.y / 2.0
	elif _bounds.position.y + _bounds.size.y > frame_bounds.position.y + frame_bounds.size.y / 2.0:
		position.y = frame_bounds.position.y + _bounds.size.y

	_bounds = calculate_bounding_rect(_sprites)
