extends EditorTranslationParserPlugin

var lookup_properties: Dictionary = {}
var exception_list: Dictionary = {}


func _init() -> void:
	# Scene Node's properties containing strings that will be fetched for translation.
	lookup_properties.set("text", true)
	lookup_properties.set("*_text", true)
	lookup_properties.set("popup/*/text", true)
	lookup_properties.set("title", true)
	lookup_properties.set("filters", true)
	#lookup_properties.set("script", true)
	lookup_properties.set("item_*/text", true)
	lookup_properties.set("accessibility_name", true)
	lookup_properties.set("accessibility_description", true)

	# Exception list (to prevent false positives).
	exception_list.set("LineEdit", [ "text" ])
	exception_list.set("TextEdit", [ "text" ])
	exception_list.set("CodeEdit", [ "text" ])
	exception_list.set("Control",  [ "tooltip_text" ])


func _parse_file(path: String) -> Array[PackedStringArray]:
	# Parse specific scene Node's properties (see in constructor) that are auto-translated by the engine when set. E.g Label's text property.
	# These properties are translated with the tr() function in the C++ code when being set or updated.

	var r_translations: Array[PackedStringArray] = []

	var packed_scene: PackedScene = ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE)
	if not packed_scene:
		push_error("Failed to load " + path + " or not a PackedScene.")
		return []

	var state := packed_scene.get_state()

	var atr_owners: Array = []
	var tabcontainer_paths: PackedStringArray = []

	for i in state.get_node_count():
		# our modification allows to add TRANSLATORS: comments from scene parser here
		var editor_description: String = ""
		for j in state.get_node_property_count(i):
			if state.get_node_property_name(i, j) == &"editor_description":
				editor_description = state.get_node_property_value(i, j)
				break
		
		var node_type := state.get_node_type(i)
		var parent_path := String(state.get_node_path(i, true))

		# Handle instanced scenes.
		if node_type.is_empty():
			var instance: PackedScene = state.get_node_instance(i)
			if instance:
				var _state := instance.get_state()
				node_type = _state.get_node_type(0)

		# Find the `auto_translate_mode` property.
		var auto_translating := true
		var auto_translate_mode_found := false
		for j in state.get_node_property_count(i):
			var property := state.get_node_property_name(i, j)
			# If an old scene wasn't saved in the new version, the `auto_translate` property won't be converted into `auto_translate_mode`,
			# so the deprecated property still needs to be checked as well.
			# TODO: Remove the check for "auto_translate" once the property if fully removed.
			if property != "auto_translate_mode" and property != "auto_translate":
				continue

			auto_translate_mode_found = true

			var idx_last := atr_owners.size() - 1
			if idx_last > 0 and not parent_path.begins_with(String(atr_owners[idx_last][0])):
				# Exit from the current owner nesting into the previous one.
				atr_owners.remove_at(idx_last)

			if property == "auto_translate_mode":
				var auto_translate_mode: int = state.get_node_property_value(i, j)
				if auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED:
					auto_translating = false
			else:
				# TODO: Remove this once `auto_translate` is fully removed.
				auto_translating = state.get_node_property_value(i, j)

			atr_owners.push_back([state.get_node_path(i), auto_translating])
			break

		# If `auto_translate_mode` wasn't found, that means it is set to its default value (`AUTO_TRANSLATE_MODE_INHERIT`).
		if not auto_translate_mode_found:
			var idx_last := atr_owners.size() - 1
			if idx_last >= 0 and parent_path.begins_with(String(atr_owners[idx_last][0])):
				auto_translating = atr_owners[idx_last][1]
			else:
				atr_owners.push_back([state.get_node_path(i), true])

		# Handle the `tooltip_auto_translate_mode` property separately.
		var tooltip_text: String = ""
		var tooltip_auto_translating := auto_translating
		for j in state.get_node_property_count(i):
			var property := state.get_node_property_name(i, j)
			if property == &"tooltip_text":
				tooltip_text = String(state.get_node_property_value(i, j))
				continue
			
			if property == &"tooltip_auto_translate_mode":
				var mode: int = state.get_node_property_value(i, j)
				match mode:
					Node.AUTO_TRANSLATE_MODE_ALWAYS:
						tooltip_auto_translating = true
					
					Node.AUTO_TRANSLATE_MODE_DISABLED:
						tooltip_auto_translating = false
					
				continue
		
		if not tooltip_text.is_empty() and tooltip_auto_translating:
			r_translations.push_back([ tooltip_text, "", "", editor_description ])
		

		# Parse the names of children of `TabContainer`s, as they are used for tab titles.
		if not tabcontainer_paths.is_empty():
			if not parent_path.begins_with(tabcontainer_paths[tabcontainer_paths.size() - 1]):
				# Switch to the previous `TabContainer` this was nested in, if that was the case.
				tabcontainer_paths.remove_at(tabcontainer_paths.size() - 1)
			
			if (
				auto_translating and not tabcontainer_paths.is_empty() and ClassDB.is_parent_class(node_type, &"Control") and
					parent_path == tabcontainer_paths[tabcontainer_paths.size() - 1]
				):
				r_translations.push_back([ state.get_node_name(i), "", "", editor_description ])
			
		if not auto_translating:
			continue

		# Handle translation context
		var translation_context: String
		if ClassDB.is_parent_class(node_type, &"Control"):
			for j in state.get_node_property_count(i):
				var property_name := state.get_node_property_name(i, j)

				if property_name == &"translation_context":
					translation_context = String(state.get_node_property_value(i, j))
					break

		if node_type == &"TabContainer":
			tabcontainer_paths.push_back(String(state.get_node_path(i)))

		for j in state.get_node_property_count(i):
			var property_name := state.get_node_property_name(i, j)

			if not match_property(property_name, node_type):
				continue

			var property_value = state.get_node_property_value(i, j)
			
			# C++ parses built-in scripts this way, which we can't really do because we can't access the other parser plugins
			# leaving this here in case there's another solution
			#if property_name == &"script" and typeof(property_value) == TYPE_OBJECT and property_value:
				## Parse built-in script.
				#var s: Script = property_value as Script
				#if not s or not s.is_built_in():
					#continue
#
				#var extension := s.get_language().get_extension()
				#if EditorTranslationParser.get_singleton().can_parse(extension):
					#EditorTranslationParser.get_singleton().get_parser(extension).parse_file(s.get_path(), r_translations)
			#el...
			if (node_type == &"FileDialog" or node_type == &"EditorFileDialog") and property_name == &"filters":
				# Extract FileDialog's filters property with values in format "*.png ; PNG Images","*.gd ; GDScript Files".
				var str_values: PackedScene = property_value
				for k in str_values.size():
					var desc: String = str_values[k].get_slicec(int(';'), 1).strip_edges()
					if desc:
						r_translations.push_back([ desc, "", "", editor_description ])

			elif typeof(property_value) == TYPE_STRING:
				var str_value := String(property_value)
				# Prevent reading text containing only spaces.
				if str_value.strip_edges():
					r_translations.push_back([ str_value, translation_context, "", editor_description ])

	return r_translations


func match_property(p_property_name: String, p_node_type: String) -> bool:
	for exception_node_type: String in exception_list:
		if ClassDB.is_parent_class(p_node_type, exception_node_type):
			var exception_properties: Array = exception_list[exception_node_type]
			for exception_property in exception_properties:
				if p_property_name.match(exception_property):
					return false
				
	for lookup_property in lookup_properties:
		if p_property_name.match(lookup_property):
			return true
		
	return false


func _get_recognized_extensions() -> PackedStringArray:
	return ["tscn"]
