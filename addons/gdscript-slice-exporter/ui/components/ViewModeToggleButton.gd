class_name ViewModeToggleButton
extends PanelContainer

signal game_button_toggled(is_pressed)
signal console_button_toggled(is_pressed)

export var hide_labels := false setget set_hide_labels

var _labels := {}
var _buttons := []

onready var _game_button := find_node("GameButton") as Button
onready var _console_button := find_node("ConsoleButton") as Button


func _ready() -> void:
	_buttons = [_game_button, _console_button]
	for button in _buttons:
		_labels[button] = button.text
	_game_button.connect("pressed", self, "_emit_toggled_signal", [_game_button])
	_console_button.connect("pressed", self, "_emit_toggled_signal", [_console_button])


func set_hide_labels(value: bool) -> void:
	hide_labels = value
	if not is_inside_tree():
		yield(self, "ready")
	for button in _buttons:
		button.text = "" if hide_labels else _labels[button]
	# Force the container to update its size based on labels
	rect_size.x = 0.0


func _emit_toggled_signal(button: Button) -> void:
	if button == _game_button:
		emit_signal("game_button_toggled", button.pressed)
	else:
		emit_signal("console_button_toggled", button.pressed)
