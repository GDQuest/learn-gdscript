tool
extends Resource
class_name SceneProperties

export var scene: PackedScene

export var viewport_size: Vector2 = Vector2(
	float(ProjectSettings.get_setting("display/window/size/width")),
	float(ProjectSettings.get_setting("display/window/size/height"))
)


func get_storage_path() -> String:
	return scene.resource_path.get_basename() + ".live-editor"


func get_save_name() -> String:
	if scene:
		var file_name := scene.resource_path.get_file()
		return file_name
	return ''


func _to_string() -> String:
	return "(%s.tscn)" % [scene.resource_path.get_file().get_basename()]
