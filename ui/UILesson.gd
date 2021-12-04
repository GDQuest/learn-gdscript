class_name UILesson
extends Control

signal lesson_completed

const LessonDonePopupScene := preload("components/LessonDonePopup.tscn")

const ContentBlockScene := preload("UIContentBlock.tscn")
const PracticeButtonScene := preload("UIPracticeButton.tscn")

var _practices := []
var _current_practice_index := 0

onready var _title := $Title as Label
onready var _content_blocks := $ContentBlocks as VBoxContainer
onready var _practices_container := $Practices as VBoxContainer

onready var _exercises_container := $Exercises as Container
onready var _next_button := find_node("NextButton") as Button


func _ready() -> void:
	setup(preload("res://course/lesson-66929/lesson.tres"))

	# TODO: instantiate practices from resources, move code to `setup()`
	for child in _exercises_container.get_children():
		if child is CourseExercise:
			var exercise := child as CourseExercise
			var index := _practices.size()
			exercise.connect("exercise_validated", self, "_on_exercise_validated", [index])
			_practices.append(exercise)

	for index in _practices.size():
		var progress = (float(index + 1) / _practices.size()) * 100
		var practice := _practices[index] as CourseExercise
		practice.progress = progress

	_practices[0].show()
	_practices[0].take_over_slice()

	_next_button.connect("pressed", self, "_on_next_button_pressed")


func setup(lesson: Resource) -> void:
	if not is_inside_tree():
		yield(self, "ready")

	_title.text = lesson.title

	for block in lesson.content_blocks:
		var instance: UIContentBlock = ContentBlockScene.instance()
		instance.setup(block)
		_content_blocks.add_child(instance)

	for practice in lesson.practices:
		var instance = PracticeButtonScene.instance()
		instance.setup(practice)
		_practices_container.add_child(instance)


func _on_exercise_validated(is_valid: bool, exercise_index: int) -> void:
	_current_practice_index = exercise_index + 1
	_next_button.disabled = not is_valid


func _on_next_button_pressed() -> void:
	var is_last_practice = _current_practice_index >= _practices.size()
	if is_last_practice:
		emit_signal("lesson_completed")
		var popup: LessonDonePopup = LessonDonePopup.instance()
		add_child(popup)
		popup.connect("pressed", Events, "emit_signal", ["lesson_end_popup_closed"])
	else:
		var practice = _practices.find(index) as CourseExercise
		practice.show()
		practice.take_over_slice()
