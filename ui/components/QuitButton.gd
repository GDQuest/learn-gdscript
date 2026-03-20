extends Button


func _ready() -> void:
	connect("pressed", Callable(get_tree(), "quit"))
	
	if OS.has_feature("JavaScript"):
		queue_free()
