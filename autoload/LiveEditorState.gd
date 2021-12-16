extends Node

signal slice_changed

var current_slice: SliceProperties setget set_current_slice
var current_scene: Node

var error_database: GDScriptErrorDatabase


func _init() -> void:
	error_database = GDScriptErrorDatabase.new()


func set_current_slice(new_slice: SliceProperties) -> void:
	if new_slice == current_slice:
		return
	current_slice = new_slice
	current_scene = current_slice.get_scene_properties().scene.instance()
	emit_signal("slice_changed")


func use_scene(parent: Node) -> void:
	var previous_parent := current_scene.get_parent()
	if previous_parent != null:
		current_scene.get_parent().remove_child(current_scene)
	parent.add_child(current_scene)
	parent.connect("tree_exited", self, "_on_scene_parent_removed")


func _on_scene_parent_removed() -> void:
	current_scene.get_parent().remove_child(current_scene)

# Updates all nodes with the given script.
# If a node path isn't valid, the node will be silently skipped
func update_nodes(script: GDScript, node_paths: Array) -> void:
	for node_path in node_paths:
		if node_path is NodePath or node_path is String:
			var node = current_scene.get_node_or_null(node_path)
			if node:
				try_validate_and_replace_script(node, script)


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
