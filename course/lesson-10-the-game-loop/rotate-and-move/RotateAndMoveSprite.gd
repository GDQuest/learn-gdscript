extends WrappingNode2D


func _ready() -> void:
	_sprites = [$GodotBottom, $HandIce, $HandIce2]
	_bounds = calculate_bounding_rect(_sprites)
	set_process(false)

# EXPORT move_and_rotate
func _process(delta):
	rotate(0.05)
# /EXPORT move_and_rotate

func _run():
	set_process(true)
