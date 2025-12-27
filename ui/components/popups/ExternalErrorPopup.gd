extends ColorRect

@onready var _confirm_button := $PanelContainer/Column/Margin/Column/Buttons/ConfirmButton as Button


func _ready() -> void:
	_confirm_button.pressed.connect(hide)
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		_confirm_button.grab_focus()
