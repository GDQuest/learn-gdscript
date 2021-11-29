extends Container

signal lesson_completed

const LessonDonePopup := preload(
	"res://addons/exporter-for-live-editor/ui/components/LessonDonePopup.tscn"
)

var _exercises := []
var _current_exercise := 0

onready var exercises_container := $Exercises as Container
onready var next_button := find_node("NextButton") as Button


func _ready() -> void:
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
