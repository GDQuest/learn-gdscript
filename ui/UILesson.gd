# Displays a Lesson ressource and a list a button to start each practice in a
# lesson.
#
# When pressing a practice button, emits an event so the navigation can
# transition to the practice screen.
class_name UILesson
extends Control

const ContentBlockScene := preload("UIContentBlock.tscn")
const QuizzInputFieldScene := preload("UIQuizzInputField.tscn")
const QuizzChoiceScene := preload("UIQuizzChoice.tscn")
const PracticeButtonScene := preload("UIPracticeButton.tscn")
const RevealerScene := preload("components/Revealer.tscn")

const COLOR_NOTE := Color(0.14902, 0.776471, 0.968627)

export var test_lesson: Resource

onready var _title := $ScrollContainer/MarginContainer/Column/Title as Label
onready var _content_blocks := (
	$ScrollContainer/MarginContainer/Column/ContentBlocks as VBoxContainer
)
onready var _practices_container := (
	$ScrollContainer/MarginContainer/Column/Practices as VBoxContainer
)


func _ready() -> void:
	if test_lesson and get_parent() == get_tree().root:
		setup(test_lesson)


func setup(lesson: Lesson) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_title.text = lesson.title

	for block in lesson.content_blocks:
		if block is ContentBlock:
			var instance: UIContentBlock = ContentBlockScene.instance()
			instance.setup(block)
			if block.type == ContentBlock.Type.PLAIN:
				_content_blocks.add_child(instance)
			else:
				var revealer := RevealerScene.instance() as Revealer
				if block.type == ContentBlock.Type.NOTE:
					revealer.text_color = COLOR_NOTE
					revealer.title = "Note"
				else:
					revealer.title = "Learn More"

				revealer.padding = 0.0
				revealer.first_margin = 0.0
				revealer.children_margin = 0.0
				_content_blocks.add_child(revealer)
				revealer.add_child(instance)
		elif block is Quizz:
			var scene = QuizzInputFieldScene if block is QuizzInputField else QuizzChoiceScene
			var instance = scene.instance()
			instance.setup(block)
			_content_blocks.add_child(instance)

	for practice in lesson.practices:
		var button: UIPracticeButton = PracticeButtonScene.instance()
		button.setup(practice)
		_practices_container.add_child(button)
		button.connect("pressed", Events, "emit_signal", ["practice_start_requested", practice])
