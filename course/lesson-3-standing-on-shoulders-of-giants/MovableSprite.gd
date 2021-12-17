extends WrappingNode2D


func _ready() -> void:
	_sprites = [$GodotBottom, $HandIce, $HandIce2]
	_bounds = calculate_bounding_rect(_sprites)


func run():
	move_local_x(20)
	move_local_y(20)
	_bounds.position += Vector2.ONE * 20
