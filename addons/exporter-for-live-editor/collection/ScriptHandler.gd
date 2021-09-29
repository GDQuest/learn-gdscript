## Manages one script. Maintains a list of nodes using that script, 
## and can replace their script.
extends Resource

const RegExp := preload("../utils/RegExp.gd")
const ScriptSlice := preload("./ScriptSlice.gd")
const EXPORT_KEY = "(?m)^(?<leading_spaces>\\t*)#\\s(?<closing>\\/)?(?<keyword>EXPORT)(?: +(?<name>[\\w\\d]+))?"


export var nodes: Array
export var file_path := ""
export var original_script := ""
export var name := ""
var _current_index := 0
var _current_array := []
export var slices := {}

var sanitization_replacements := RegExp.collection({
	"\\r\\n": "\\n",
})

var export_key_regex := RegExp.compile(EXPORT_KEY)
var leading_spaces_regex := RegExp.compile("(?m)^(?:  )+")

func _init() -> void:
	nodes = []

func set_initial_script(initial_script: GDScript) -> void:
	file_path = initial_script.resource_path
	name = file_path.get_file().get_basename()
	original_script = initial_script.source_code
	slices = _get_script_slices(original_script)


func _to_string():
	return '`%s`' % [file_path]


func _iterator_is_valid() -> bool:
	return _current_index < _current_array.size()


func _iter_init(_arg) -> bool:
	_current_index = 0
	_current_array = slices.keys()
	return _iterator_is_valid()


func _iter_next(_arg) -> bool:
	_current_index += 1
	return _iterator_is_valid()


func _iter_get(_arg):
	return current_key()


func size() -> int:
	return nodes.size()


func current_key() -> String:
	var key = _current_array[_current_index]
	return key


func current() -> ScriptSlice:
	return get_slice(current_key())


func get_slice(key: String) -> ScriptSlice:
	return slices[key]


func add_node(path: NodePath) -> void:
	nodes.append(path)


func _get_script_slices(script: String):
	var sanitized_text := sanitization_replacements.replace(script)
	var lines := sanitized_text.split("\n")
	var waiting_slices := {}
	var completed_slices := {}
	for index in lines.size():
		var line: String = lines[index]
		var spacesMatch := leading_spaces_regex.search(line)
		if spacesMatch:
			var spaces: String = spacesMatch.strings[0]
			var length = spaces.length()
			var replacement = "\\t".repeat(length/ 2)
			line = replacement + line.substr(length)
		var exportMatch := export_key_regex.search(line)
		if exportMatch:
			var slice = ScriptSlice.new()
			slice.from_regex_match(exportMatch)
			slice.start = index
			if slice.closing and slice.name:
				if slice.name in waiting_slices:
					var previous_slice: ScriptSlice = waiting_slices[slice.name]
					waiting_slices.erase(slice.name)
					previous_slice.end = index
					previous_slice.set_main_lines(lines)
					completed_slices[slice.name] = previous_slice
			elif slice.name:
				waiting_slices[slice.name] = slice
			elif slice.global:
				slice.set_main_lines(lines, true)
				slice.end = lines.size()
				completed_slices['*'] = slice
	return completed_slices
