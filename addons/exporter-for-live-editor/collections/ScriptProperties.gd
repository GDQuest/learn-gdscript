extends Resource

export var nodes_paths := PoolStringArray()
# Path to the GDScript file
export var file_path := "" setget set_file_path
# Basename of the GDScript file. Helps to display the name in the UI
export var file_name := ""
# Full text of the script
export var original_script := ""

func set_initial_script(initial_script: GDScript) -> void:
	set_file_path(initial_script.resource_path)
	original_script = initial_script.source_code


func set_file_path(path: String) -> void:
	file_path = path
	file_name = file_path.get_file().get_basename()

func get_save_name() -> String:
	return file_path.get_file()
