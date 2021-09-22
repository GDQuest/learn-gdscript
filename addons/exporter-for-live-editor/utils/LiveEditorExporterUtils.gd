extends Node

const SceneScriptsRepository := preload("../collection/SceneScriptsRepository.gd")
const SceneScript := SceneScriptsRepository.SceneScript

const SETTINGS_KEY = preload("./config.gd").SETTINGS_KEY

const REGEX_PRINTS = "\\bprints\\((.*?)\\)"
const REGEX_PRINT = "\\bprint\\((.*?)\\)"
const REGEX_PUSH_ERROR = "\\bpush_error\\((.*?)\\)"
const REGEX_PUSH_WARNING = "\\bpush_warning\\((.*?)\\)"
const REGEX_EXPORT = "(?m)^(\\s*)#\\s(EXPORT)(?:(?:\\s+)(.*?))?(?:\\s|$)"

var _replacements = {
	REGEX_PRINTS: "EventBus.print_log([$1])",
	REGEX_PRINT: "EventBus.print_log([$1])",
	REGEX_PUSH_ERROR: "EventBus.print_error($1)",
	REGEX_PUSH_WARNING: "EventBus.print_warning($1)",
}

var export_key_regex = RegEx.new()


func _init() -> void:
	var regexes = _replacements.keys()
	export_key_regex.compile(REGEX_EXPORT)
	for key in regexes:
		var replacement = _replacements[key]
		var regex = RegEx.new()
		regex.compile(key)
		_replacements.erase(key)
		_replacements[regex] = replacement


func replace_code(text: String) -> String:
	for regex in _replacements:
		var replacement = _replacements[regex]
		text = regex.sub(text, replacement, true)
	return text


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
	print("is " + script.resource_path + " valid?")
	var result = export_key_regex.search(script.source_code)
	if result:
		print("it's valid")
		return true
	print("it's invalid")
	return false


func _collect_scripts(scene: Node, node: Node, repository: SceneScriptsRepository, limit: int):
	var maybe_script: Reference = node.get_script()
	if maybe_script != null and maybe_script is GDScript:
		var script: GDScript = maybe_script
		if script_is_valid(script):
			repository.add_node(script, node)
	if limit > 0:
		limit -= 1
		for child in node.get_children():
			_collect_scripts(scene, child, repository, limit)


func collect_script(scene: Node, limit := 1000) -> SceneScriptsRepository:
	var repository := SceneScriptsRepository.new(scene)
	_collect_scripts(scene, scene, repository, limit)
	return repository
