extends Button

func _ready() -> void:
	pressed.connect(get_tree().quit)

	if OS.has_feature("web"):
		queue_free()
