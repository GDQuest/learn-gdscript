extends Node

onready var _popup := $Panel as Control
onready var _title := $Panel/MarginContainer/Column/Title as Label
onready var _content := $Panel/MarginContainer/Column/Content as RichTextLabel


func _ready() -> void:
	_popup.hide()
	_popup.connect("mouse_exited", _popup, "hide")


func setup(term: String, bbcode_text: String) -> void:
	if not is_inside_tree():
		yield(self, "ready")
	_title.text = term
	_content.bbcode_text = bbcode_text


func show():
	_popup.show()


func align_with_mouse(global_mouse_position: Vector2) -> void:
	_popup.rect_global_position = global_mouse_position
