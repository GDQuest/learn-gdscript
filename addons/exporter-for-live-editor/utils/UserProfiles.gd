# 
# Singleton for saving and loading user profiles
# Use it like so:
# 
# var profile = UserProfiles.get_profile("MyPlayer")
# profile.set_exercise_progress("exercise_name", 5)
# 
extends Node

const ROOT_DIR := "user://user_settings"

var current_player := "Player"

signal progress_changed(exercise_name, progress)


func profile_exists(file_name: String) -> bool:
	var file_path := _get_file_path(file_name)
	return File.new().file_exists(file_path)


# Returns the profile designated by the provided name.
# If the profile does not exist, it will be created on the fly, so if you do not
# want that to happen, check with `profile_exists` first, or use `get_profile_or_die`
# loading a profile will set it as the current file name
func get_profile(file_name: String = current_player) -> Profile:
	if file_name != current_player:
		current_player = file_name
	var file_path := _get_file_path(file_name)
	if not profile_exists(file_name):
		var fs = Directory.new()
		var directory := file_path.get_base_dir()
		fs.make_dir_recursive(directory)
		var user_profile := Profile.new()
		user_profile.file_path = file_path
		user_profile.player_name = file_name
		user_profile.connect("progress_changed", self, "_on_exercise_progress_changed")
		return user_profile
	return load(file_path) as Profile


func _get_file_path(file_name: String) -> String:
	return ROOT_DIR.plus_file(file_name) + ".tres"


func list_profiles() -> PoolStringArray:
	var profiles := PoolStringArray()
	var dir := Directory.new()
	var error = dir.open(ROOT_DIR)
	if error != OK:
		profiles.push_back(current_player)
		return profiles
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "" and not dir.current_is_dir() and file_name.get_extension() == "tres":
		var player_name = (load(file_name) as Profile).player_name
		profiles.push_back(player_name)
	return profiles


func _on_exercise_progress_changed(exercise_name, progress) -> void:
	emit_signal("progress_changed", exercise_name, progress)

class Profile:
	extends Resource

	signal progress_changed(exercise_name, progress)

	var file_path = ""
	export var player_name := ""
	export var exercises := {} setget _read_only

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
		if not file_path:
			push_error("cannot save a file without a filename, set file_path first")
			return
		ResourceSaver.save(file_path, self)


class Exercise:
	export var name := ""
	export var progress := 0
