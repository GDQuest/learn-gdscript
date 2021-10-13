extends Container

const Exercise := preload("./Exercise.gd")

signal lesson_completed

onready var exercises_container := $Exercises as Container
onready var next_button := $PanelContainer/HBoxContainer/NextButton as Button

var _exercises := []
var _current_exercise := 0

func _ready() -> void:
	for child in exercises_container.get_children():
		if child is Exercise:
			var exercise := child as Exercise
			var index := _exercises.size()
			_exercises.append(exercise)
			exercise.connect("exercise_validated", self, "_on_exercise_validated", [index])
	
	for index in _exercises.size():
		var progress = (float(index + 1) / _exercises.size()) * 100
		var exercise := _exercises[index] as Exercise
		exercise.progress = progress
	
	next_button.connect("pressed", self, "_on_next_button_pressed")

func _on_exercise_validated(is_valid: bool, exercise_index: int) -> void:
	next_button.disabled = not is_valid
	_current_exercise = exercise_index + 1


func _on_next_button_pressed() -> void:
	if _current_exercise > _exercises.size():
		print("complete!")
		emit_signal("lesson_completed")
		return
	for index in _exercises.size():
		var exercise := _exercises[index] as Exercise
		var show = index == _current_exercise
		exercise.visible = show
