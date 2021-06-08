tool
extends VBoxContainer

export var title := "Expand" setget set_title, get_title
export var collapsed := false setget set_collapsed

onready var _title_node: RichTextLabel = $HBoxContainer/Title
onready var _button: Button = $HBoxContainer/RevealButton
onready var _container: HBoxContainer = $HBoxContainer

func _ready() -> void:
	_button.pressed = not collapsed
	_button.connect("toggled", self, "_on__button_toggled")
	set_collapsed(collapsed)

func _on__button_toggled(_toggled: bool) -> void:
	toggle()

func toggle() -> void:
	set_collapsed(not collapsed)

func set_collapsed(new_collapsed: bool) -> void:
	collapsed = new_collapsed
	if not is_inside_tree(): yield(self, "ready")
	if collapsed:
		_button.text = ">"
		for child in get_children():
			if child != _container:
				child.hide()
	else:
		_button.text = "V"
		for child in get_children():
			child.show()

func set_title(new_title: String) -> void:
	if not is_inside_tree(): yield(self, "ready")
	_title_node.bbcode_text = new_title

func get_title() -> String:
	return _title_node.bbcode_text
