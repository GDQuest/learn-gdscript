extends ColorRect

@onready var _center_container: CenterContainer = %CenterContainer
@onready var _confirm_button: Button = %ConfirmButton


func _ready():
	_confirm_button.pressed.connect(hide)
	visibility_changed.connect(
		func _on_visibility_changed() -> void:
			_center_container.visible = visible
			if visible:
				_confirm_button.grab_focus(),
	)
