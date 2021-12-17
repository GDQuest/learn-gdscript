class_name Profile
extends Resource

signal progress_changed(exercise_name, progress)

export var player_name := ""
export var exercises := {} #setget _read_only # This seem to fail on load, so commenting out for now.

export var font_size_scale := 0

func _get_or_create_exercise(exercise_name: String) -> Exercise:
	var exercise := get_exercise(exercise_name)
	if not exercise:
		exercise = Exercise.new()
		exercise.name = exercise_name
		exercises[exercise_name] = exercise
	return exercise

func get_exercise(exercise_name: String) -> Exercise:
	if not exercise_name in exercises:
		return null
	return exercises[exercise_name] as Exercise

func set_exercise_progress(exercise_name: String, progress := 0, and_save := true) -> void:
	_get_or_create_exercise(exercise_name).progress = progress
	emit_signal("progress_changed", exercise_name, progress)
	if and_save:
		save()

func get_exercise_progress(exercise_name: String) -> int:
	if not exercise_name in exercises:
		return 0
	return (exercises[exercise_name] as Exercise).progress

func _read_only(_bogus_variable) -> void:
	push_error("do not try to change this variable")

func save() -> void:
	if resource_path.empty():
		push_error("cannot save a file without a filename, set resource_path first")
		return
	ResourceSaver.save(resource_path, self)
	take_over_path(resource_path)


class Exercise:
	export var name := ""
	export var progress := 0
