# Displays a Lesson ressource and a list a button to start each practice in a
# lesson.
#
# When pressing a practice button, emits an event so the navigation can
# transition to the practice screen.
class_name UILesson
extends Control

const ContentBlockScene := preload("UIContentBlock.tscn")
const QuizInputFieldScene := preload("UIQuizInputField.tscn")
const QuizChoiceScene := preload("UIQuizChoice.tscn")
const PracticeButtonScene := preload("UIPracticeButton.tscn")
const RevealerScene := preload("components/Revealer.tscn")

const COLOR_NOTE := Color(0.14902, 0.776471, 0.968627)

export var test_lesson: Resource

onready var _title := $ScrollContainer/MarginContainer/Column/Title as Label
onready var _content_blocks := $ScrollContainer/MarginContainer/Column/ContentBlocks as VBoxContainer
onready var _practices_container := $ScrollContainer/MarginContainer/Column/Column/Practices as VBoxContainer
onready var _practices_visibility_container := $ScrollContainer/MarginContainer/Column/Column as VBoxContainer

var _visible_index := -1
var _quizzes_done := 0
var _quizz_count := 0


func _ready() -> void:
	if test_lesson and get_parent() == get_tree().root:
		setup(test_lesson)


func setup(lesson: Lesson) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_title.text = lesson.title

	var quiz_index := 0

	for block in lesson.content_blocks:
		if block is ContentBlock:
			var instance: UIContentBlock = ContentBlockScene.instance()
			instance.setup(block)
			if block.type == ContentBlock.Type.PLAIN:
				_content_blocks.add_child(instance)
				instance.hide()
			else:
				var revealer := RevealerScene.instance() as Revealer
				revealer.hide()
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
				instance.set_draw_panel(true)

		elif block is Quiz:
			var scene = QuizInputFieldScene if block is QuizInputField else QuizChoiceScene
			var instance = scene.instance()
			_content_blocks.add_child(instance)
			instance.setup(block)
			instance.hide()
			instance.connect("quiz_passed", Events, "emit_signal", ["quiz_completed", quiz_index])
			instance.connect("quiz_passed", self, "_reveal_up_to_next_quiz")
			instance.connect("quiz_skipped", self, "_reveal_up_to_next_quiz")

			quiz_index += 1
	_quizz_count = quiz_index + 1

	for practice in lesson.practices:
		var button: UIPracticeButton = PracticeButtonScene.instance()
		button.setup(practice)
		_practices_container.add_child(button)
	_practices_visibility_container.hide()
	_reveal_up_to_next_quiz()


func _reveal_up_to_next_quiz() -> void:
	_quizzes_done += 1
	var child_count := _content_blocks.get_child_count()
	while _visible_index < child_count - 1:
		_visible_index += 1
		var child = _content_blocks.get_child(_visible_index)
		child.show()
		if child is UIQuizChoice or child is UIQuizInputField:
			break

	if _visible_index == child_count - 1 and _quizzes_done == _quizz_count:
		_practices_visibility_container.show()
