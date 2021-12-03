class_name UILesson
extends Control


signal lesson_completed

const LessonDonePopupScene := preload("components/LessonDonePopup.tscn")

const ContentBlockScene := preload("UIContentBlock.tscn")
const PracticeButtonScene := preload("UIPracticeButton.tscn")

var _exercises := []
var _current_exercise := 0

onready var _title := $Title as Label
onready var _content_blocks := $ContentBlocks as VBoxContainer
onready var _practices := $Practices as VBoxContainer


onready var exercises_container := $Exercises as Container
onready var next_button := find_node("NextButton") as Button

func _ready() -> void:
	setup(preload("res://course/lesson-66929/lesson.tres"))

	for child in exercises_container.get_children():
		if child is CourseExercise:
			var exercise := child as CourseExercise
			var index := _exercises.size()
			exercise.connect("exercise_validated", self, "_on_exercise_validated", [index])
			_exercises.append(exercise)

	for index in _exercises.size():
		var progress = (float(index + 1) / _exercises.size()) * 100
		var exercise := _exercises[index] as CourseExercise
		exercise.progress = progress
		if index == 0:
			_activate_exercise(exercise, true)
		else:
			_activate_exercise(exercise, false)

	next_button.connect("pressed", self, "_on_next_button_pressed")


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
		_practices.add_child(instance)







func _on_exercise_validated(is_valid: bool, exercise_index: int) -> void:
	_current_exercise = exercise_index + 1
	next_button.disabled = not is_valid


func _on_next_button_pressed() -> void:
	if _current_exercise >= _exercises.size():
		emit_signal("lesson_completed")
		var popup: LessonDonePopup = LessonDonePopup.instance()
		add_child(popup)
		popup.connect("pressed", Events, "emit_signal", ["lesson_end_popup_closed"])
	else:
		for index in _exercises.size():
			var exercise := _exercises[index] as CourseExercise
			var show = index == _current_exercise
			if show:
				_activate_exercise(exercise, true)
			else:
				_activate_exercise(exercise, false)


func _activate_exercise(exercise: CourseExercise, activate: bool) -> void:
	if activate:
		exercise.take_over_slice()
		exercise.visible = true
	else:
		exercise.visible = false
