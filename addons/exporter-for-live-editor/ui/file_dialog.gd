extends FileDialog


func _init() -> void:
	mode = FileDialog.MODE_OPEN_FILE
	access = FileDialog.ACCESS_RESOURCES
	set_filters(PoolStringArray(["*.tscn ; Godot Scenes"]))
