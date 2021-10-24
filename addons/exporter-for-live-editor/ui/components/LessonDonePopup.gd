extends PanelContainer

onready var _button := $VBoxContainer/MarginContainer/VBoxContainer/Button as Button


func _ready() -> void:
	_button.connect("pressed", self, "queue_free")
