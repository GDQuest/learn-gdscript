class_name UIPracticeButton
extends Node

signal pressed

var completed_before := false setget set_completed_before
var is_highlighted := false setget set_is_highlighted

onready var _title_label := $Margin/Row/Column/Title as Label
onready var _description_label := $Margin/Row/Column/Description as Label
onready var _button := $Margin/Row/Button as Button
onready var _completed_before_icon := $Margin/Row/CompletedBeforeIcon as TextureRect


func _ready() -> void:
	_completed_before_icon.visible = completed_before


func setup(practice: Practice) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_title_label.text = practice.title
	_description_label.text = practice.description
	_description_label.visible = not practice.description.empty()
	_button.connect("pressed", NavigationManager, "navigate_to", [practice.resource_path])


func set_completed_before(value: bool) -> void:
	completed_before = value
	if is_inside_tree():
		_completed_before_icon.visible = completed_before


func set_is_highlighted(value: bool) -> void:
	is_highlighted = value

	if not is_inside_tree():
		yield(self, "ready")

	_button.add_stylebox_override("normal", preload("res://ui/theme/button_outlined_accent_normal.tres"))
	_button.add_stylebox_override("hover", preload("res://ui/theme/button_outlined_accent_hover.tres"))
	_button.add_stylebox_override("pressed", preload("res://ui/theme/button_outlined_accent_pressed.tres"))
	_button.add_color_override("font_color", Color("3dff6e"))
	_button.add_color_override("font_color_focus", Color("3dff6e"))
	_button.add_color_override("font_color_hover", Color("c1ffd1"))
	_button.add_color_override("font_color_pressed", Color("1fb850"))
