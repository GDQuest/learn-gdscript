# Singleton for saving and loading user profiles
#
# Can implicitly create profiles on access, so it is safe to use without checks.
# The returned profile can be used to change user settings or access course progression.
#
extends Node

@export var player_name: String = ""

const ROOT_DIR := "user://user_settings"

var current_player := "Player"
var _loaded_profile: Profile

func profile_exists(profile_name: String) -> bool:
	var file_path := _get_file_path(profile_name)
	return FileAccess.file_exists(file_path)


# Returns the profile designated by the provided name.
# If the profile does not exist, it will be created on the fly. If you do not
# want that to happen, check with `profile_exists` first.
#
# Loading a profile will set it as the current file name.
func get_profile(profile_name: String = current_player) -> Profile:
	if profile_name == current_player and _loaded_profile:
		return _loaded_profile
	
	current_player = profile_name
	var file_path := _get_file_path(profile_name)
	
	if not profile_exists(profile_name):
		var directory := file_path.get_base_dir()
		DirAccess.make_dir_recursive_absolute(directory)
		
		var user_profile := Profile.new()
		user_profile.resource_path = file_path
		user_profile.player_name = profile_name
		
		_loaded_profile = user_profile
		Log.info({
			"profileName":profile_name
			}, "created profile")
		return user_profile
	
	Log.info({
		"profileName":profile_name
		}, "loaded profile")
	_loaded_profile = ResourceLoader.load(file_path) as Profile
	return _loaded_profile


func _get_file_path(file_name: String) -> String:
	return ROOT_DIR.path_join(file_name) + ".tres"


func list_profiles() -> PackedStringArray:
	var profiles := PackedStringArray()

	var fs := DirAccess.open(ROOT_DIR)
	if fs == null:
		profiles.append(current_player)
		return profiles

	fs.list_dir_begin()
	var file_name := fs.get_next()
	while file_name != "":
		if fs.current_is_dir() or file_name.get_extension() != "tres":
			file_name = fs.get_next()
			continue

		var full_path := ROOT_DIR.path_join(file_name)
		var profile := ResourceLoader.load(full_path) as Profile
		if profile != null:
			profiles.append(profile.player_name)

		file_name = fs.get_next()

	return profiles
