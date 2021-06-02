## Manages one script. Maintains a list of nodes using that script, and can
## replace their script.
extends Reference

const ScriptVerifier := preload("./ScriptVerifier.gd")

signal errors(errors)

var nodes := []
var original_script := ""
var current_script := ""
var script_object: GDScript
var file_path := ""
var name := ""
var cached_file := false
var _node: Node
var _replacements = {
	"\\bprints\\((.*?)\\)": "EventBus.print_log([$1])",
	"\\bprint\\((.*?)\\)": "EventBus.print_log([$1])",
	"\\bpush_error\\((.*?)\\)": "EventBus.print_error($1)",
	"\\bpush_warning\\((.*?)\\)": "EventBus.print_warning($1)",
}


func _init(initial_script: GDScript, node: Node) -> void:
	script_object = initial_script
	_node = node
	name = script_object.resource_path.get_file().get_basename()
	original_script = script_object.source_code
	current_script = original_script
	var directory_path = script_object.resource_path.get_base_dir().replace("res://", "")
	var directory = Directory.new()
	directory.open("user://")
	directory.make_dir_recursive(directory_path)
	file_path = "user://".plus_file(directory_path.plus_file(name))
	# TODO: Can we do this only once instead of once per instance?
	var regexes = _replacements.keys()
	for key in regexes:
		var replacement = _replacements[key]
		var regex = RegEx.new()
		regex.compile(key)
		_replacements.erase(key)
		_replacements[regex] = replacement


func _to_string():
	return '`%s`' % [script_object.resource_path]


## Takes the provided text, compiles it as a new GDScript, saves it to the user's
## data dir, and applies it to each node using the script.
## Emits an array of errors if the script has compilation errors.
func attempt_apply(new_script_text: String) -> void:
	for regex in _replacements:
		var replacement = _replacements[regex]
		new_script_text = regex.sub(new_script_text, replacement, true)

	if new_script_text == current_script:
		return
	var new_script := GDScript.new()
	new_script.source_code = new_script_text
	var suffix := ".b" if cached_file else ".a"
	var current_file_name := file_path + suffix + ".gd"
	ResourceSaver.save(current_file_name, new_script)

	var verifier = ScriptVerifier.new(_node, new_script_text)
	verifier.test()

	var errors: Array = yield(verifier, "errors")
	var severity := 100
	if errors.size():
		for i in range(errors.size() - 1, -1, -1):
			var error = errors[i]
			# unused return value.
			if error.code == 16:
				errors.remove(i)
		for error in errors:
			# warning-ignore:narrowing_conversion
			severity = min(severity, error.severity)

	if severity < 2:
		emit_signal("errors", errors)
		return

	for node in nodes:
		node.script = load(current_file_name)

	cached_file = not cached_file
	current_script = new_script_text
	emit_signal("errors", errors)


# Tests a script to ensure it has no errors.
# Returns
func test(current_file_name: String) -> bool:
	var test_file: Resource = load(current_file_name)
	var test_instance = test_file.new()
	return test_instance != null
