class_name UIPracticeButton
extends Node

signal pressed

var completed_before := false setget set_completed_before

onready var _label := $Row/Label as Label
onready var _button := $Row/Button as Button
onready var _completed_before_icon := $Row/CompletedBeforeIcon as TextureRect


func _ready() -> void:
	_completed_before_icon.visible = completed_before


func setup(practice: Practice) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_label.text = practice.title
	_button.connect("pressed", NavigationManager, "navigate_to", [practice.resource_path])


func set_completed_before(value: bool) -> void:
	completed_before = value
	if is_inside_tree():
		_completed_before_icon.visible = completed_before
