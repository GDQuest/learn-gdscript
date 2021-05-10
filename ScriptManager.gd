# Manages one script. Maintains a list of nodes using that script, and can 
# replace their script
var nodes := []
var original_script := ""
var current_script := ""
var script_object: GDScript
var file_path := ""
var name := ""
var cached_file := false

func _init(initial_script: GDScript) -> void:
	script_object = initial_script
	name = script_object.resource_path.get_file().get_basename()
	original_script = script_object.source_code
	current_script = original_script
	var directory_path = script_object.resource_path.get_base_dir().replace("res://","")
	var directory = Directory.new()
	directory.open("user://")
	directory.make_dir_recursive(directory_path)
	file_path = "user://".plus_file(directory_path.plus_file(name))

func _to_string():
	return '`%s`'%[script_object.resource_path]

# Takes the provided string, compiles it as a new GDScript, saves it to the user's
# data dir, and applies it to each node using the script
func apply(new_script_text: String) -> void:
	if new_script_text == current_script:
			return
	var new_script = GDScript.new()
	new_script.source_code = new_script_text
	var suffix = ".b" if cached_file else ".a"
	var current_file_name = file_path+suffix+".gd"
	ResourceSaver.save(current_file_name, new_script)
	if not test(current_file_name):
		return
	for node in nodes:
		node.script = load(current_file_name)
	cached_file = not cached_file
	current_script = new_script_text

# tests a script to verify it is valid (no syntax errors)
static func test(current_file_name: String) -> bool:
	var test_file = load(current_file_name)
	var test_instance = test_file.new()
	if test_instance != null:
		return true
	return false
