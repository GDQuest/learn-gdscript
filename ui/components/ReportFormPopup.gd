extends ColorRect

onready var _confirm_button := $PanelContainer/Column/Margin/Column/ConfirmButton as Button


func _ready():
	_confirm_button.connect("pressed", self, "hide")
