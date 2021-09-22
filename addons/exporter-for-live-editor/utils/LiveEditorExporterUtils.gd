extends Node

const SceneFiles := preload("../collection/SceneFiles.gd")
const RegExp := preload("./RegExp.gd")

var export_key_regex := RegExp.compile(SceneFiles.ScriptHandler.EXPORT_KEY)

const SETTINGS_KEY = preload("./config.gd").SETTINGS_KEY

var script_replacements := RegExp.collection({
	"\\bprints\\((.*?)\\)": "EventBus.print_log([$1])",
	"\\bprint\\((.*?)\\)": "EventBus.print_log([$1])",
	"\\bpush_error\\((.*?)\\)": "EventBus.print_error($1)",
	"\\bpush_warning\\((.*?)\\)": "EventBus.print_warning($1)",
})

# Returns a string representing the current scene,
# or an empty string
static func get_scene() -> String:
	var path = ProjectSettings.get_setting(SETTINGS_KEY)
	if path:
		return path
	return ""

# loads the selected scene. Accepts an optional `from`
# argument which checks that the loaded scene isn't itself
static func load_scene(from: Node = null) -> Node:
	var scene_path = get_scene()
	if scene_path:
		if from and from.filename == scene_path:
			return null
		var packed_scene: PackedScene = load(scene_path)
		var scene = packed_scene.instance()
		return scene
	return null

# Tests a script to ensure it has no errors.
# Only works at runtime
static func test(current_file_name: String) -> bool:
	var test_file: Resource = load(current_file_name)
	var test_instance = test_file.new()
	return test_instance != null


func script_is_valid(script: GDScript) -> bool:
	var result = export_key_regex.search(script.source_code)
	if result:
		return true
	return false


func _collect_scripts(scene: Node, node: Node, repository: SceneFiles, limit: int):
	var maybe_script: Reference = node.get_script()
	if maybe_script != null and maybe_script is GDScript:
		var script: GDScript = maybe_script
		if script_is_valid(script):
			repository.add_node(script, node)
	if limit > 0:
		limit -= 1
		for child in node.get_children():
			_collect_scripts(scene, child, repository, limit)


func collect_script(scene: Node, limit := 1000) -> SceneFiles:
	var repository := SceneFiles.new(scene)
	_collect_scripts(scene, scene, repository, limit)
	return repository
