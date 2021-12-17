# 
# Singleton for saving and loading user profiles
# Use it like so:
# 
# var profile = UserProfiles.get_profile("MyPlayer")
# profile.set_exercise_progress("exercise_name", 5)
# 
extends Node

signal progress_changed(exercise_name, progress)

const ROOT_DIR := "user://user_settings"

var current_player := "Player"
var _loaded_profile: Profile

func profile_exists(profile_name: String) -> bool:
	var file_path := _get_file_path(profile_name)
	return File.new().file_exists(file_path)


# Returns the profile designated by the provided name.
# If the profile does not exist, it will be created on the fly, so if you do not
# want that to happen, check with `profile_exists` first, or use `get_profile_or_die`.
# Loading a profile will set it as the current file name.
func get_profile(profile_name: String = current_player) -> Profile:
	if profile_name == current_player and _loaded_profile:
		return _loaded_profile
	
	current_player = profile_name
	var file_path := _get_file_path(profile_name)
	
	if not profile_exists(profile_name):
		var fs = Directory.new()
		var directory := file_path.get_base_dir()
		fs.make_dir_recursive(directory)
		
		var user_profile := Profile.new()
		user_profile.resource_path = file_path
		user_profile.player_name = profile_name
		user_profile.connect("progress_changed", self, "_on_exercise_progress_changed")
		
		_loaded_profile = user_profile
		return user_profile
	
	_loaded_profile = ResourceLoader.load(file_path) as Profile
	return _loaded_profile


func _get_file_path(file_name: String) -> String:
	return ROOT_DIR.plus_file(file_name) + ".tres"


func list_profiles() -> PoolStringArray:
	var profiles := PoolStringArray()
	
	var fs := Directory.new()
	var error = fs.open(ROOT_DIR)
	if error != OK:
		profiles.push_back(current_player)
		return profiles
	
	fs.list_dir_begin()
	var file_name := fs.get_next()
	while not file_name.empty():
		if fs.current_is_dir() or file_name.get_extension() != "tres":
			file_name = fs.get_next()
			continue
		
		var profile = ResourceLoader.load(file_name) as Profile
		if profile:
			profiles.push_back(profile.player_name)
		
		file_name = fs.get_next()

	return profiles


func _on_exercise_progress_changed(exercise_name, progress) -> void:
	emit_signal("progress_changed", exercise_name, progress)
