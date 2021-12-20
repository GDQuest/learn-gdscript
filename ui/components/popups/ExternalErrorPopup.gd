extends ColorRect

onready var _confirm_button := $PanelContainer/Column/Margin/Column/Buttons/ConfirmButton as Button


func _ready():
	_confirm_button.connect("pressed", self, "hide")
