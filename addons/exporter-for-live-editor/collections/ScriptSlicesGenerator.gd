#
# Collects, and exports (saves to disk), all slices from a scene.
# This class functions mostly as a parser. Except a few exceptions, the entire class could almost be 
# written as one large procedural function.
# 
# There's only one interesting method: `export_scene_slices`. Refer to it for more information
#
const RegExp := preload("../utils/RegExp.gd")
const SceneProperties = preload("./SceneProperties.gd")
const ScriptProperties = preload("./ScriptProperties.gd")
const ScriptSliceProperties := preload("./ScriptSliceProperties.gd")

# Regular expressions used in parsing the scripts

var _sanitization_replacements := RegExp.collection(
	{
		"\\r\\n": "\\n",
	}
)
var _leading_spaces_regex := RegExp.compile("(?m)^(?:  )+")
var _export_annotation_regex := RegExp.compile("(?m)^(?<_leading_spaces_regex>\\t*)#\\s(?<closing>\\/)?(?<keyword>EXPORT)(?: +(?<name>[\\w\\d]+))?")

# /Regular expressions

# Created when collecting a scene and exporting slices.
var _scene_properties: SceneProperties
# Set to `true` as soon as at least one annotation is found
var _found_one_annotation := false

# Collects all the scripts in a scene, and parses slices that have an EXPORT annotation.
# Running this will save:
# - one resource file representing scene properties
# - a resource file per script (one or more)
# - one resource file per slice (one per script or more)
# If no annotation is found, this is a (quasi) no-op (it does add then remove a node)
# A node needs to be passed so the packed scene can be instanciated and analyzed. While the scene
# is free'd at the end of the process, the passed node_in_tree itself isn't.
# @param packed_scene PackedScene  The scene to parse
# @param node_in_tree Node         Any node that is added to the tree. The instanciated scene will 
#                                  be added to it
# @param limit        int          A maximal recursion depth 
func export_scene_slices(packed_scene: PackedScene, node_in_tree: Node, limit := 1000) -> void:
	if not node_in_tree.is_inside_tree():
		yield(node_in_tree, "ready")
	
	_scene_properties = SceneProperties.new()
	_scene_properties.scene = packed_scene
	
	var unpacked_scene = packed_scene.instance()
	# Add the scene to a node so we can hide the node
	# hiding the scene directly can fail if the scene
	# doesn't extend CanvasItem
	var container_node := Node2D.new()
	node_in_tree.add_child(container_node)
	container_node.hide()
	container_node.add_child(unpacked_scene)
	
	_collect_node_scripts(unpacked_scene, unpacked_scene, limit)
	
	container_node.remove_child(unpacked_scene)
	node_in_tree.remove_child(container_node)
	unpacked_scene.queue_free()
	container_node.queue_free()

# Loops all children. If a child has a script, verifies its script contains
# the specified annotation EXPORT.
# If it does, adds the node to the list of handled nodes.
func _collect_node_scripts(scene: Node, node: Node, limit: int) -> void:
	var maybe_script: Reference = node.get_script()
	if maybe_script != null and maybe_script is GDScript:
		var script := maybe_script as GDScript
		var script_has_annotation := _export_annotation_regex.search(script.source_code) != null
		if script_has_annotation == true:
			if not _found_one_annotation:
				_found_one_annotation = true
				# first annotation found:
				_save(_scene_properties)
			_add_node_path_to_script(scene, script, node)
	if limit > 0:
		limit -= 1
		for child in node.get_children():
			_collect_node_scripts(scene, child, limit)


# If the provided script is new, adds a script file to the _script_paths. Otherwise,
# adds the provided node as a dependency of this script.
func _add_node_path_to_script(root_scene: Node, script: GDScript, node: Node) -> void:
	var root_node_path := String(root_scene.get_path()) + "/"
	var node_path := NodePath(String(node.get_path()).replace(root_node_path, ""))
	var script_properties_path := _generate_save_path(script.resource_path.get_file())
	var script_already_exists := File.new().file_exists(script_properties_path)
	var script_properties := (
		(load(script_properties_path) as ScriptProperties) 
		if script_already_exists
		else _parse_new_script(script)
	)
	script_properties.nodes_paths.append(node_path)
	_save(script_properties)

# The provided script will be parsed, a properties file created, and saved to disk
func _parse_new_script(script: GDScript) -> ScriptProperties:
	
	var script_properties := ScriptProperties.new()
	script_properties.set_initial_script(script)
	_save(script_properties)
		
	var blueprint_segment = ScriptSliceProperties.new()
	blueprint_segment.script_properties = script_properties
	blueprint_segment.scene_properties = _scene_properties
	var slices := _parse_script_slices(script.source_code, blueprint_segment)
	for index in slices.size():
		var slice := slices[index] as ScriptSliceProperties
		_save(slice)
	return script_properties


# Splits a script in slices according to the EXPORT comments and returns them as
# an Array[ScriptSliceProperties].
func _parse_script_slices(script: String, blueprint_segment: ScriptSliceProperties) -> Array:
	var sanitized_text := _sanitization_replacements.replace(script)
	var lines := sanitized_text.split("\n")
	var waiting_slices := {}
	var completed_slices := {}
	for index in lines.size():
		var line: String = lines[index]
		var spaces_match := _leading_spaces_regex.search(line)
		if spaces_match:
			var spaces: String = spaces_match.strings[0]
			var length = spaces.length()
			var replacement = "\\t".repeat(length / 2)
			line = replacement + line.substr(length)

		var export_match := _export_annotation_regex.search(line)
		if export_match:
			var slice := ScriptSliceProperties.new()
			slice.script_properties = blueprint_segment.script_properties
			slice.scene_properties = blueprint_segment.scene_properties
			slice.from_regex_match(export_match)
			slice.start = index
			if slice.closing and slice.name:
				if slice.name in waiting_slices:
					var previous_slice: ScriptSliceProperties = waiting_slices[slice.name]
					waiting_slices.erase(slice.name)
					previous_slice.end = index
					previous_slice.set_main_lines(lines)
					completed_slices[slice.name] = previous_slice
			elif slice.name:
				waiting_slices[slice.name] = slice
			elif slice.global:
				slice.set_main_lines(lines, true)
				slice.end = lines.size()
				completed_slices["*"] = slice
	return completed_slices.values()

func _generate_save_path(save_name: String) -> String:
	var directory = _scene_properties.get_storage_path()
	var path = directory.plus_file(save_name) + ".live-editor.tres"
	return path

func _save(resource: Resource) -> bool:
	var directory = _scene_properties.get_storage_path()
	if not Directory.new().file_exists(directory):
		var could_create_directories = Directory.new().make_dir_recursive(directory)
		if could_create_directories != OK:
			push_error("failed to create directory %s"%[directory])
			return false
	var is_valid_resource = resource.has_method('get_save_name')
	if not is_valid_resource:
		assert(is_valid_resource, "Resource %s does not have a get_save_name method"%[resource])
		return false
	var path = _generate_save_path(resource.get_save_name())
	var success = ResourceSaver.save(path, resource)
	if success != OK:
		push_error("error saving %s to %s"%[resource, path])
		return false
	return true
	
