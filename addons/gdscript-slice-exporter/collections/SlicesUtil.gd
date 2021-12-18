#
# Collects, and exports (saves to disk), all slices from a scene.
# This class functions mostly as a parser. Except a few exceptions, the entire class could almost be 
# written as one large procedural function.
# 
# There's only one interesting method: `export_scene_slices`. Refer to it for more information
#
class_name SlicesUtils

const RESOURCE_TYPES = {"SCENE": 'scene', "SCRIPT": 'scripts', "SLICE": 'slices'}

# Regular expressions used in parsing the scripts

var _sanitization_replacements := RegExpGroup.collection(
	{
		"\\r\\n": "\\n",
	}
)
var _leading_spaces_regex := RegExpGroup.compile("(?m)^(?:  )+")
var _export_annotation_regex := RegExpGroup.compile(
	"(?m)^(?<leading_spaces>\\t*)#\\s(?<closing>\\/)?(?<keyword>EXPORT)(?: +(?<name>[\\w\\d]+))?"
)

# /Regular expressions

# Created when collecting a scene and exporting slices.
var _scene_properties: SceneProperties
# Set to `true` as soon as at least one annotation is found
var _found_one_annotation := false

# Holds references to already encountered scripts
# @type Dictionary[String, ScriptProperties]
var _cached_script_properties := {}


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
				_save(RESOURCE_TYPES.SCENE, _scene_properties)
			_add_node_path_to_script(scene, script, node)
	if limit > 0:
		limit -= 1
		for child in node.get_children():
			_collect_node_scripts(scene, child, limit)


# If the provided script is new, adds a script file to the _script_paths. Otherwise,
# adds the provided node as a dependency of this script.
func _add_node_path_to_script(root_scene: Node, script: GDScript, node: Node) -> void:
	var root_node_path := String(root_scene.get_path())
	var node_path_str := String(node.get_path()).replace(root_node_path, "")
	if node_path_str.begins_with("/"):
		node_path_str = node_path_str.substr(1)
	var node_path := NodePath(node_path_str)
	var script_properties_path := _generate_save_path(
		RESOURCE_TYPES.SCRIPT, script.resource_path.get_file()
	)
	if not (script_properties_path in _cached_script_properties):
		_parse_new_script(script, script_properties_path)
	var script_properties := _cached_script_properties[script_properties_path] as ScriptProperties
	if script_properties.nodes_paths.find(node_path) < 0:
		script_properties.nodes_paths.append(node_path)
	_save(RESOURCE_TYPES.SCRIPT, script_properties)


# The provided script will be parsed, a properties file created, and saved to disk
func _parse_new_script(script: GDScript, script_properties_path: String) -> ScriptProperties:
	var script_properties := ScriptProperties.new()
	script_properties.script_file = script
	_save(RESOURCE_TYPES.SCRIPT, script_properties)

	var blueprint_segment = SliceProperties.new()
	blueprint_segment.script_properties = script_properties
	blueprint_segment.scene_properties = _scene_properties
	var slices := _parse_script_slices(script.source_code, blueprint_segment)
	for index in slices.size():
		var slice := slices[index] as SliceProperties
		_save(RESOURCE_TYPES.SLICE, slice)
	_cached_script_properties[script_properties_path] = script_properties
	return script_properties


# Splits a script in slices according to the EXPORT comments and returns them as
# an Array[SliceProperties]
func _parse_script_slices(script: String, blueprint_segment: SliceProperties) -> Array:
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
			var slice := SliceProperties.new()
			slice.script_properties = blueprint_segment.script_properties
			slice.scene_properties = blueprint_segment.scene_properties
			slice.from_regex_match(export_match)
			#prints("slice:", slice, ", line:", "|"+line+"|")
			slice.start = index
			if slice.closing and slice.name:
				if slice.name in waiting_slices:
					var previous_slice: SliceProperties = waiting_slices[slice.name]
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


func _generate_save_directory(type: String) -> String:
	return _scene_properties.get_storage_path().plus_file(type)


func _generate_save_path(type: String, save_name: String) -> String:
	var directory = _generate_save_directory(type)
	var path = directory.plus_file(save_name) + ".tres"
	return path


func _save(type: String, resource: Resource) -> bool:
	var directory = _generate_save_directory(type)
	if not Directory.new().file_exists(directory):
		var could_create_directories = Directory.new().make_dir_recursive(directory)
		if could_create_directories != OK:
			push_error("failed to create directory %s" % [directory])
			return false
	var is_valid_resource = resource.has_method('get_save_name')
	if not is_valid_resource:
		assert(is_valid_resource, "Resource %s does not have a get_save_name method" % [resource])
		return false
	var path = _generate_save_path(type, resource.get_save_name())
	resource.take_over_path(path)
	var success = ResourceSaver.save(path, resource)
	if success != OK:
		push_error("error saving %s to %s" % [resource, path])
		return false
	return true


# Returns a list of files in a directory that match a regex pattern.
# Does not recurse.
# This is not, strictly, related to slices, but it's here for keeping indirection low. Might get
# moved later
# @param path          String Path to the root directory
# @param regex_pattern String A pattern to match against (as a String, it will be parsed to regex)
static func _list_files_in_dir(path: String, regex_pattern := ".*") -> PoolStringArray:
	var dir = Directory.new()
	var valid_regex := RegEx.new()
	valid_regex.compile(regex_pattern)
	if not (dir.open(path) == OK):
		push_error("Cannot open directory %s" % [path])
		return PoolStringArray()
	dir.list_dir_begin()
	var files := PoolStringArray()
	var file_name = dir.get_next()
	while file_name != "":
		var is_valid = (not dir.current_is_dir()) and valid_regex.search(file_name) != null
		if is_valid:
			files.append(path.plus_file(file_name))
		file_name = dir.get_next()
	return files

# Returns paths to all scripts properties files in a directory
static func list_scripts_properties_in_dir(path: String) -> PoolStringArray:
	var scripts_paths := path.plus_file(RESOURCE_TYPES.SCRIPT)
	return _list_files_in_dir(scripts_paths, '\\.gd\\.tres$')

# Returns paths to all slices properties files in a directory
static func list_slices_properties_in_dir(path: String) -> PoolStringArray:
	return _list_files_in_dir(path.plus_file(RESOURCE_TYPES.SLICE), '\\.slice\\.tres$')

# Returns an exported scene properties from a given scene file
# @param packed_scene PackedScene The scene. It must have been exported prior through the plugin 
# @returns SceneProperties
static func load_scene_properties_from_scene(packed_scene: PackedScene) -> SceneProperties:
	var scene_properties := SceneProperties.new()
	scene_properties.scene = packed_scene
	var path := (
		scene_properties.get_storage_path().plus_file(RESOURCE_TYPES.SCENE).plus_file(
			scene_properties.get_save_name()
		)
		+ ".tres"
	)
	return load(path) as SceneProperties

# Returns all scripts in use (and exported) from a scene.
# @returns
static func load_scripts_from_scene_properties(scene_properties: SceneProperties) -> Array:
	var path = scene_properties.resource_path.get_base_dir().get_base_dir()
	var files_paths := list_scripts_properties_in_dir(path)
	var files := []
	for file_path in files_paths:
		var script_properties := load(file_path) as ScriptProperties
		files.append(script_properties)
	return files

# Returns all slices associated with a script file
# 
static func load_slices_from_script_properties(script_properties: ScriptProperties) -> Array:
	var path = script_properties.resource_path.get_base_dir().get_base_dir()
	var files_paths := list_slices_properties_in_dir(path)
	var files := []
	for file_path in files_paths:
		var slice_properties := load(file_path) as SliceProperties
		if slice_properties.script_properties == script_properties:
			files.append(slice_properties)
	return files
