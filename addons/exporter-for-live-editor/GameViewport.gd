extends ViewportContainer

const SceneFiles := preload("./collection/SceneFiles.gd")
const ScriptHandler := preload("./collection/ScriptHandler.gd")
const ScriptSlice := preload("./collection/ScriptSlice.gd")

var _scene: Node
var _scene_files: SceneFiles setget set_scene_files
var _viewport := Viewport.new()
var scene_paused := false setget set_scene_paused

export(Resource) var exported_scene: Resource setget set_exported_scene, get_exported_scene


func _init() -> void:
	_viewport.name = "Viewport"
	add_child(_viewport)


static func pause_node(node: Node, pause := true, limit := 1000) -> void:
	node.set_process(not pause)
	node.set_physics_process(not pause)
	node.set_process_input(not pause)
	node.set_process_internal(not pause)
	node.set_process_unhandled_input(not pause)
	node.set_process_unhandled_key_input(not pause)
	if limit > 0:
		limit -= 1
		for child in node.get_children():
			pause_node(child, pause, limit)


func set_scene_files(new_scene_files: SceneFiles) -> void:
	if _scene_files == new_scene_files or not new_scene_files:
		return
	if not is_inside_tree():
		yield(self, "ready")
	if _scene:
		_viewport.remove_child(_scene)
		_scene.queue_free()
	_scene_files = new_scene_files
	_scene = _scene_files.scene.instance()
	_viewport.size = _scene_files.scene_viewport_size
	_viewport.add_child(_scene)


func update_nodes(script: GDScript, node_paths: Array) -> void:
	for node_path in node_paths:
		var node = _scene.get_node(node_path)
		node.set_script(script)


func pause_scene(pause := true, limit := 1000) -> void:
	if not _scene:
		return
	if scene_paused == pause:
		return
	scene_paused = pause
	pause_node(_scene, pause, limit)


func toggle_scene_pause() -> void:
	pause_scene(not scene_paused)


func set_scene_paused(is_it: bool) -> void:
	pause_scene(is_it)


func set_exported_scene(new_scene_files: Resource) -> void:
	assert(new_scene_files != null, "no scene slices provided")
	var scene_files := new_scene_files as SceneFiles
	assert(
		scene_files is SceneFiles,
		"file '%s' is not an instance of SceneFiles." % [new_scene_files.resource_path]
	)
	set_scene_files(scene_files)


func get_exported_scene() -> SceneFiles:
	return _scene_files
