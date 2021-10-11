# Holds a scene, and offers some utilities to play it, pause it,
# and replace scripts on running nodes
extends ViewportContainer

const SceneFiles := preload("../collections/SceneFiles.gd")
const ScriptHandler := preload("../collections/ScriptHandler.gd")
const ScriptSlice := preload("../collections/ScriptSlice.gd")

var _scene: Node
var _viewport := Viewport.new()
var scene_paused := false setget set_scene_paused

# Must be a SceneFiles resource
export (Resource) var scene_files: Resource setget set_scene_files, get_scene_files


func _init() -> void:
	_viewport.name = "Viewport"
	add_child(_viewport)


func _ready() -> void:
	get_tree().connect("screen_resized", self, "_on_screen_resized")
	get_tree().call_deferred("emit_signal", "screen_resized")


# Recursively pauses a node and its children
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

# Updates all nodes with the given script.
# If a node path isn't valid, the node will be silently skipped
func update_nodes(script: GDScript, node_paths: Array) -> void:
	for node_path in node_paths:
		if node_path is NodePath or node_path is String:
			var node = _scene.get_node_or_null(node_path)
			if node:
				try_validate_and_replace_script(node, script)


# Pauses the current GameViewport scene
func pause_scene(pause := true, limit := 1000) -> void:
	if not _scene:
		return
	if scene_paused == pause:
		return
	scene_paused = pause
	pause_node(_scene, pause, limit)


# Toggles a scene's paused state on and off
func toggle_scene_pause() -> void:
	pause_scene(not scene_paused)


func set_scene_paused(is_it: bool) -> void:
	pause_scene(is_it)


func set_scene_files(new_scene_files: Resource) -> void:
	assert(new_scene_files != null, "no scene slices provided")
	assert(
		new_scene_files is SceneFiles,
		"file '%s' is not an instance of SceneFiles." % [new_scene_files.resource_path]
	)
	# Reads a SceneFile resource, and sets the scene contained within as the
	# child of the viewport
	if scene_files == new_scene_files or not new_scene_files:
		return
	scene_files = new_scene_files
	if not is_inside_tree():
		yield(self, "ready")
	if _scene:
		_viewport.remove_child(_scene)
		_scene.queue_free()
	var _scene_files := scene_files as SceneFiles
	_scene = _scene_files.scene.instance()
	_viewport.size = _scene_files.scene_viewport_size
	_viewport.add_child(_scene)



func get_scene_files() -> SceneFiles:
	return scene_files as SceneFiles


func _on_screen_resized() -> void:
	_viewport.size = rect_size


static func try_validate_and_replace_script(node: Node, script: Script) -> void:
	if not script.can_instance():
		var error_code := script.reload()
		if not script.can_instance():
			print("Script errored out (code %s); skipping replacement" % [error_code])
			return

	var props := {}
	for prop in node.get_property_list():
		if prop.name == "script":
			continue
		props[prop.name] = node.get(prop.name)

	node.set_script(script)

	for prop in props:
		if prop in node:  # In case a property is removed
			node.set(prop, props[prop])
