class_name UIPracticeButton
extends Node

signal pressed

onready var _label := $Row/Label as Label
onready var _button := $Row/Button as Button


func setup(practice: Practice) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_label.text = practice.title
	_button.connect("pressed", NavigationManager, "navigate_to", [practice.resource_path])
