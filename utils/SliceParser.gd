# Utility script to parse EXPORT comments from GDScript source code at runtime.
# We use this to extract and display code the student can edit and that we
# insert into practice scripts.
class_name SliceParser

# Regular expression to match EXPORT comments
# Matches: # EXPORT name or # /EXPORT name or # EXPORT
const EXPORT_REGEX_PATTERN := "^\\s*#\\s*(/)?EXPORT(?:\\s+(\\w+))?\\s*$"

# Parses a slice from script source code
# script_source: The full GDScript source code
# slice_name: Name of the slice to extract (empty string = first EXPORT found)
# Dictionary with: {lines_before, lines_after, lines_editable, leading_spaces, start, end}
static func parse_slice(script_source: String, slice_name: String = "") -> Dictionary:
	var lines := Array(script_source.split("\n"))
	var export_regex := RegEx.new()
	export_regex.compile(EXPORT_REGEX_PATTERN)
	
	var target_slice_name := slice_name
	var export_start_line := -1
	var export_end_line := -1
	var found_closing := false
	var found_any_slice := false
	
	# Find the EXPORT comments
	for i in range(lines.size()):
		var match_result := export_regex.search(lines[i])
		if not match_result:
			continue
		
		var is_closing := match_result.get_string(1) == "/"
		var matched_name := match_result.get_string(2)
		
		if is_closing:
			# If we found the matching closing tag we're done
			if export_start_line >= 0 and matched_name == target_slice_name:
				export_end_line = i
				found_closing = true
				break
			continue
		
		if export_start_line < 0:
			if target_slice_name.empty():
				target_slice_name = matched_name if matched_name else ""
				export_start_line = i
				found_any_slice = true
			elif matched_name == target_slice_name:
				export_start_line = i
				found_any_slice = true
	
	if export_start_line < 0:
		push_error("EXPORT slice not found: " + (target_slice_name if not target_slice_name.empty() else "(any)"))
		return {}
	
	if not found_closing:
		push_error("Closing /EXPORT tag not found for slice: " + target_slice_name)
		return {}
	
	# Extract lines from the script.
	# The lines before is everything up to (but not including) the # EXPORT line
	# Editable lines range from after # EXPORT to (but not including) the # /EXPORT line
	# Lines after is the rest.
	var lines_before := lines.slice(0, export_start_line)
	var editable_start := export_start_line + 1
	var lines_editable := lines.slice(editable_start, export_end_line - 1)
	var lines_after := lines.slice(export_end_line + 1, lines.size())
	
	var leading_spaces := 0
	if lines_editable.size() > 0:
		var first_line: String = lines_editable[0]
		for i in range(first_line.length()):
			if first_line[i] == "\t":
				leading_spaces += 1
			elif first_line[i] == " ":
				leading_spaces += 0.5
			else:
				break
		leading_spaces = int(leading_spaces)
		
		# Remove leading indentation from editable lines
		if leading_spaces > 0:
			for i in range(lines_editable.size()):
				var line: String = lines_editable[i]
				var tabs_to_remove := leading_spaces
				var chars_to_remove := 0
				for j in range(line.length()):
					if tabs_to_remove <= 0:
						break
					if line[j] == "\t":
						chars_to_remove += 1
						tabs_to_remove -= 1
					elif line[j] == " ":
						chars_to_remove += 1
						tabs_to_remove -= 0.5
						if tabs_to_remove <= 0:
							break
					else:
						break
				if chars_to_remove > 0:
					lines_editable[i] = line.substr(chars_to_remove)
	
	var start_line := export_start_line
	var end_line := export_end_line
	
	return {
		"lines_before": lines_before,
		"lines_after": lines_after,
		"lines_editable": lines_editable,
		"leading_spaces": leading_spaces,
		"start": start_line,
		"end": end_line,
		"slice_name": target_slice_name
	}


# Finds all EXPORT slice names in a script and returns an Array of slice names
# found in the script
static func find_all_slice_names(script_source: String) -> Array:
	var lines := Array(script_source.split("\n"))
	var export_regex := RegEx.new()
	export_regex.compile(EXPORT_REGEX_PATTERN)
	
	var slice_names := []
	for line in lines:
		var match_result := export_regex.search(line)
		if match_result and match_result.get_string(1) != "/":
			var name := match_result.get_string(2)
			if name and not name in slice_names:
				slice_names.append(name)
	return slice_names


# Loads a ScriptSlice from a .gd script file
# script_path: Path to the .gd file
# slice_name: Name of the EXPORT slice to extract (empty = first one found)
# returns ScriptSlice resource with parsed data
static func load_from_script(script_path: String, slice_name: String = "") -> ScriptSlice:
	if script_path.is_rel_path():
		script_path = "res://" + script_path
	elif not script_path.begins_with("res://"):
		push_error("Script path must be a resource path: " + script_path)
		return null
	
	if not Engine.editor_hint:
		script_path = script_path.replace(".gd", ".lgd")
	
	var file := File.new()
	if file.open(script_path, File.READ) != OK:
		push_error("Failed to read script file: " + script_path)
		return null
	
	var script_source := file.get_as_text()
	file.close()
	
	var parsed_data := parse_slice(script_source, slice_name)
	if parsed_data.empty():
		return null
	
	var slice := ScriptSlice.new()
	slice.script_path = script_path
	slice.slice_name = parsed_data.get("slice_name", "")
	slice.start = parsed_data.get("start", 0)
	slice.end = parsed_data.get("end", 0)
	slice.leading_spaces = parsed_data.get("leading_spaces", 0)
	slice.lines_before = parsed_data.get("lines_before", [])
	slice.lines_after = parsed_data.get("lines_after", [])
	slice.lines_editable = parsed_data.get("lines_editable", [])
	
	return slice

