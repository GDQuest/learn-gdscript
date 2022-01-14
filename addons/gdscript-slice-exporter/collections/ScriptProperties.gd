tool
extends Resource
class_name ScriptProperties

export var nodes_paths := []
# Path to the GDScript file
export var script_file: GDScript setget set_script_file
# Full text of the script
export(String, MULTILINE) var original_script := ""

# Basename of the GDScript file. Helps to display the name in the UI
var file_name := "" setget , get_file_name

# full path of the GDScript file. Useful to locate the original file
var file_path := "" setget , get_file_path

func _init() -> void:
	nodes_paths = []

func set_script_file(new_script_file: GDScript) -> void:
	script_file = new_script_file
	original_script = script_file.source_code


func get_file_name() -> String:
	return script_file.resource_path.get_file().get_basename() if script_file else ""

func get_file_path() -> String:
	return script_file.resource_path if script_file else ""

func get_save_name() -> String:
	assert(script_file != null, "no script file set")
	if script_file:
		return script_file.resource_path.get_file()
	return ""


func _to_string() -> String:
	return "(%s.gd)" % [file_name]
