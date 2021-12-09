# Displays a Lesson ressource and a list a button to start each practice in a
# lesson.
#
# When pressing a practice button, emits an event so the navigation can
# transition to the practice screen.
class_name UILesson
extends Control

const ContentBlockScene := preload("UIContentBlock.tscn")
const PracticeButtonScene := preload("UIPracticeButton.tscn")

onready var _title := $ScrollContainer/MarginContainer/Column/Title as Label
onready var _content_blocks := $ScrollContainer/MarginContainer/Column/ContentBlocks as VBoxContainer
onready var _practices_container := $ScrollContainer/MarginContainer/Column/Practices as VBoxContainer


func setup(lesson: Resource) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_title.text = lesson.title

	for block in lesson.content_blocks:
		var instance: UIContentBlock = ContentBlockScene.instance()
		instance.setup(block)
		_content_blocks.add_child(instance)

	for practice in lesson.practices:
		var button: UIPracticeButton = PracticeButtonScene.instance()
		button.setup(practice)
		_practices_container.add_child(button)
		button.connect("pressed", Events, "emit_signal", ["practice_start_requested", practice])
