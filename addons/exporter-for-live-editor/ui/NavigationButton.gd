extends BaseButton

export var url := ""
export var is_back_button := false

func _ready() -> void:
	if is_back_button:
		connect("pressed", NavigationManager, "back")
	elif url:
		connect("pressed", NavigationManager, "open_url", [url])
	else:
		disabled = true
