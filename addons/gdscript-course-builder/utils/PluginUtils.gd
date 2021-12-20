extends Object

const PLUGIN_DIR_NAME := "course-builder-for-live-editor"
const SETTINGS_SUBPATH := "addons"
const CACHE_FILE_NAME := "cache.cfg"
const TEMP_PLAY_SUBPATH := "tmpplay"

static func find_plugin_instance(from_node: Node) -> EditorPlugin:
	var node := from_node.get_parent()

	while node:
		var plugin_instance = node.get("plugin_instance")
		if plugin_instance:
			return plugin_instance
		node = node.get_parent()

	return null

static func get_settings_directory(from_node: Node) -> String:
	var plugin_instance := find_plugin_instance(from_node)
	if not plugin_instance:
		return ""

	var settings_dir := plugin_instance.get_editor_interface().get_editor_settings().get_project_settings_dir()
	return settings_dir.plus_file(SETTINGS_SUBPATH).plus_file(PLUGIN_DIR_NAME)

static func get_cache_file(from_node: Node) -> String:
	var settings_dir = get_settings_directory(from_node)
	if settings_dir.empty():
		return ""

	return settings_dir.plus_file(CACHE_FILE_NAME)

static func get_temp_play_path(from_node: Node) -> String:
	var settings_dir = get_settings_directory(from_node)
	if settings_dir.empty():
		return ""

	return settings_dir.plus_file(TEMP_PLAY_SUBPATH)
