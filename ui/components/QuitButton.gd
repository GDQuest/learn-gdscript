extends Button

func _ready() -> void:
	# Godot 4 uses the signal.connect(callable) syntax
	pressed.connect(get_tree().quit)
	
	# "web" is the standard feature tag for Web/HTML5 exports in Godot 4
	if OS.has_feature("web"):
		queue_free()
