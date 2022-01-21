class_name UIPracticeButton
extends Node

signal pressed

var completed_before := false setget set_completed_before
var is_highlighted := false setget set_is_highlighted

onready var _title_label := $Margin/Row/Column/Row/Title as Label
onready var _next_pill_label := $Margin/Row/Column/Row/NextPill as Label

onready var _description_label := $Margin/Row/Column/Description as Label
onready var _button := $Margin/Row/Button as Button
onready var _completed_before_icon := $Margin/Row/Column/Row/CompletedBeforeIcon as TextureRect


func _ready() -> void:
	_completed_before_icon.visible = completed_before


func setup(practice: Practice) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_title_label.text = practice.title.capitalize()
	_description_label.text = practice.description
	_description_label.visible = not practice.description.empty()
	_button.connect("pressed", NavigationManager, "navigate_to", [practice.resource_path])


func set_completed_before(value: bool) -> void:
	completed_before = value
	if not _completed_before_icon:
		yield(self, "ready")

	_completed_before_icon.visible = completed_before


func set_is_highlighted(value: bool) -> void:
	is_highlighted = value

	if not is_inside_tree():
		yield(self, "ready")
	
	_next_pill_label.visible = is_highlighted
	_button.add_stylebox_override("normal", preload("res://ui/theme/button_outlined_accent_normal.tres"))
	_button.add_stylebox_override("hover", preload("res://ui/theme/button_outlined_accent_hover.tres"))
	_button.add_stylebox_override("pressed", preload("res://ui/theme/button_outlined_accent_pressed.tres"))
	_button.add_color_override("font_color", Color("26c6f7"))
	_button.add_color_override("font_color_focus", Color("26c6f7"))
	_button.add_color_override("font_color_hover", Color("f5fafa"))
	_button.add_color_override("font_color_pressed", Color("1e85e0"))
