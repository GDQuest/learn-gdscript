extends PanelContainer

signal pressed()

onready var _button := $VBoxContainer/MarginContainer/VBoxContainer/Button as Button
onready var _label := $VBoxContainer/MarginContainer/VBoxContainer/Label2 as Label

export var text := "You've completed the lesson" setget set_text

func _ready() -> void:
	_button.connect("pressed", self, "_on_button_pressed")


func _on_button_pressed() -> void:
	emit_signal("pressed")
	queue_free()


func set_text(new_text: String) -> void:
	text = new_text
	if not is_inside_tree():
		yield(self, "ready")
	_label.text = text
