extends ColorRect

@onready var _confirm_button := $PanelContainer/Column/Margin/Column/Buttons/ConfirmButton as Button


func _ready():
	_confirm_button.connect("pressed", Callable(self, "hide"))
	connect("visibility_changed", Callable(self, "_on_visibility_changed"))


func _on_visibility_changed() -> void:
	if visible:
		_confirm_button.grab_focus()
