extends ColorRect

onready var _confirm_button := $PanelContainer/Column/Margin/Column/Buttons/ConfirmButton as Button


func _ready():
	_confirm_button.connect("pressed", self, "hide")
	connect("visibility_changed", self, "_on_visibility_changed")


func _on_visibility_changed() -> void:
	if visible:
		_confirm_button.grab_focus()
