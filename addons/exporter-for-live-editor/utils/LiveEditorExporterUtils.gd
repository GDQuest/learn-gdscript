extends Node

const SceneFiles := preload("../collections/SceneFiles.gd")
const RegExp := preload("./RegExp.gd")

var export_key_regex := RegExp.compile(SceneFiles.ScriptHandler.EXPORT_KEY)

const SETTINGS_KEY = preload("./config.gd").SETTINGS_KEY

# Returns a string representing the current scene or an empty string
static func get_scene() -> String:
	var path = ProjectSettings.get_setting(SETTINGS_KEY)
	if path:
		return path
	return ""

# Loads the selected scene. Accepts an optional `from` argument which checks
# that the loaded scene isn't itself.
static func load_scene(from: Node = null) -> Node:
	var scene_path = get_scene()
	if not scene_path:
		return null
	if from and from.filename == scene_path:
		return null

	var packed_scene: PackedScene = load(scene_path)
	var scene = packed_scene.instance()
	return scene
