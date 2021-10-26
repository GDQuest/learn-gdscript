class_name ViewModeToggleButton
extends PanelContainer

export var hide_labels := false setget set_hide_labels

var split_container: SplitContainer

var _labels := {}
var _buttons := []

onready var _game_button := find_node("GameButton") as Button
onready var _console_button := find_node("ConsoleButton") as Button


func _ready() -> void:
	_buttons = [_game_button, _console_button]
	for button in _buttons:
		_labels[button] = button.text
		button.connect("pressed", self, "_update_split_container")


func set_hide_labels(value: bool) -> void:
	hide_labels = value
	if not is_inside_tree():
		yield(self, "ready")
	for button in _buttons:
		button.text = "" if hide_labels else _labels[button]
	# Force the container to update its size based on labels
	rect_size.x = 0.0


func _update_split_container() -> void:
	if not split_container:
		return

	var split_height := 0
	if _console_button.pressed:
		if _game_button.pressed:
			split_height = split_container.rect_size.y / 2
		else:
			split_height = split_container.rect_size.y
	split_container.split_offset = split_height
