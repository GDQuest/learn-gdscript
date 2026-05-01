## Manager for user profiles. Can implicitly create profiles on access,
## so it is safe to use without checks. The returned profile can be used
## to change user settings or access study progression.
class_name UserProfiles extends RefCounted

const ROOT_DIR := "user://user_settings_4"

static var _current_profile_name: String = "Player"
static var _current_profile: Profile = null


## Returns a list of profiles available in the file system. Profiles
## are loaded and validated in the process. If a file system error
## occurs, this method still returns the name of the current profile.
func list_profiles() -> PackedStringArray:
	var profiles := PackedStringArray()

	var fs := DirAccess.open(ROOT_DIR)
	if not fs:
		push_error("UserProfiles: Failed to open profile root folder at '%s' for reading (code %d)." % [ROOT_DIR, DirAccess.get_open_error()])
		profiles.push_back(_current_profile_name)
		return profiles

	for file in fs.get_files():
		if not file.get_extension() != "tres":
			continue

		var profile := ResourceLoader.load(file) as Profile
		if is_instance_valid(profile):
			profiles.push_back(profile.player_name)

	return profiles


## Returns [code]true[/code] if the specified user profile exists in the
## file system.
static func profile_exists(profile_name: String) -> bool:
	var file_path := _get_profile_file_path(profile_name)
	return FileAccess.file_exists(file_path)


## Returns profile data for the specified user profile. If the profile
## doesn't exist, it is created on the fly. Makes the retrieved profile
## the current one for the app.
static func get_profile(profile_name: String = _current_profile_name) -> Profile:
	if profile_name == _current_profile_name and is_instance_valid(_current_profile):
		return _current_profile

	_current_profile_name = profile_name
	var file_path := _get_profile_file_path(profile_name)

	if profile_exists(profile_name):
		_current_profile = ResourceLoader.load(file_path) as Profile
		if is_instance_valid(_current_profile):
			return _current_profile

	var profile_directory := file_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(profile_directory)

	_current_profile = Profile.new()
	_current_profile.resource_path = file_path
	_current_profile.player_name = profile_name

	return _current_profile


# Helpers.

static func _get_profile_file_path(file_name: String) -> String:
	return ROOT_DIR.path_join("%s.tres" % file_name)
