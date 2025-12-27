extends Resource
class_name Documentation

const COLOR_TYPE := Color(0.84511, 0.83905, 0.921875)
const COLOR_MEMBER := Color(0.960784, 0.980392, 0.980392)
const COLOR_PARAMETER := Color(0.84511, 0.83905, 0.921875)
const COLOR_VALUE := Color(0.369263, 0.373399, 0.472656)

# Godot 4: use export_file for file picker hints
@export_file("*.csv") var documentation_file: String = ""

# Stores instances of MethodSpecification and PropertySpecification.
var _references := { "methods": {}, "properties": {} }


# Returns the raw reference objects for the requested names.
func get_references(names: PackedStringArray) -> QueryResult:
	# Load CSV docstrings if necessary.
	if (_references["methods"] as Dictionary).is_empty() and (_references["properties"] as Dictionary).is_empty():
		assert(
			documentation_file != "",
			"documentation file for `%s` not specified" % [resource_path]
		)
		_references = _parse_documentation_file(documentation_file)

	var result := QueryResult.new()
	for name in names:
		if (_references["methods"] as Dictionary).has(name):
			result.methods.append((_references["methods"] as Dictionary)[name])
		elif (_references["properties"] as Dictionary).has(name):
			result.properties.append((_references["properties"] as Dictionary)[name])
	return result


# Returns the reference as formatted BBCode text for the requested names.
func get_references_as_bbcode(names: PackedStringArray) -> String:
	var selected_references := get_references(names)
	if selected_references.is_empty():
		return ""

	var bbcode := ""
	if not selected_references.methods.is_empty():
		bbcode += "[b]Method descriptions[/b]"
		for ref_item in selected_references.methods:
			var m := ref_item as MethodSpecification
			if m != null:
				bbcode += "\n\n" + m.to_bbcode()

	if not selected_references.properties.is_empty():
		bbcode += "\n\n[b]Property descriptions[/b]"
		for ref_item in selected_references.properties:
			var p := ref_item as PropertySpecification
			if p != null:
				bbcode += "\n\n" + p.to_bbcode()


	return bbcode


static func _parse_documentation_file(path: String) -> Dictionary:
	var all_references := { "methods": {}, "properties": {} }

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("Failed to open documentation CSV: %s" % path)
		return all_references

	# read header
	var _header := file.get_csv_line()

	while not file.eof_reached():
		var csv_line := file.get_csv_line()
		if csv_line.is_empty():
			break
		if csv_line[0] == "":
			break

		var kind: String = csv_line[4]
		if kind == "method":
			var method_spec := MethodSpecification.new()
			method_spec.name = csv_line[0]

			var return_type: String = String(csv_line[1]).strip_edges()
			method_spec.return_type = return_type if return_type != "" else "void"

			method_spec.parameters = _parse_parameters(String(csv_line[2]))
			method_spec.explanation = String(csv_line[3]).strip_edges()

			(all_references["methods"] as Dictionary)[method_spec.name] = method_spec

		elif kind == "property":
			var property_spec := PropertySpecification.new()
			property_spec.name = csv_line[0]

			var t: String = String(csv_line[1]).strip_edges()
			property_spec.type = t if t != "" else "void"

			property_spec.explanation = String(csv_line[3])
			property_spec.default_value = String(csv_line[5])

			(all_references["properties"] as Dictionary)[property_spec.name] = property_spec

		else:
			printerr("Unknown kind for line %s: %s" % [csv_line, kind])

	return all_references


static func _parse_parameters(parameters_list_string: String) -> MethodParameterList:
	parameters_list_string = parameters_list_string.strip_edges()

	var parameters := MethodParameterList.new()
	if parameters_list_string == "":
		return parameters

	var parameters_list := parameters_list_string.split(",")
	for tuple_str in parameters_list:
		var tuple: PackedStringArray = PackedStringArray(tuple_str.split(":"))

		var param := MethodParameter.new()
		param.name = tuple[0].strip_edges()

		if tuple.size() > 1:
			var type_parts := tuple[1].strip_edges().split("=")
			param.type = String(type_parts[0]).strip_edges()

			if type_parts.size() > 1:
				param.default = String(type_parts[1]).strip_edges()
				param.required = false

		parameters.list.append(param)

	return parameters


class MethodParameter:
	var name := ""
	var required := true
	var type := "Variant"
	var default := ""

	func _to_string() -> String:
		if required:
			return "%s: %s" % [name, type]
		return "%s: %s = %s" % [name, type, default]

	func to_bbcode() -> String:
		var name_string := "[b][color=#%s]%s[/color][/b]" % [COLOR_PARAMETER.to_html(), name]
		var type_bbcode := "[color=#%s]%s[/color]" % [COLOR_TYPE.to_html(), type]
		var value_string := "[b][color=#%s]%s[/color][/b]" % [COLOR_VALUE.to_html(), default]

		if required:
			return "%s: %s" % [name_string, type_bbcode]
		return "%s: %s = %s" % [name_string, type_bbcode, value_string]


class MethodParameterList:
	var list: Array = []

	func _to_string() -> String:
		var parts := PackedStringArray()
		for item in list:
			parts.append(str(item))
		return ", ".join(parts)

	func to_bbcode() -> String:
		var parts := PackedStringArray()
		for param in list:
			parts.append((param as MethodParameter).to_bbcode())
		return ", ".join(parts)



class MethodSpecification:
	var name := ""
	var return_type := "void"
	var parameters := MethodParameterList.new()
	var explanation := ""

	func _to_string() -> String:
		return "%s %s(%s)" % [return_type, name, parameters]

	func to_bbcode() -> String:
		var type_bbcode := "[color=#%s]%s[/color]" % [COLOR_TYPE.to_html(), return_type]
		var name_string := "[b][color=#%s]%s[/color][/b]" % [COLOR_MEMBER.to_html(), name]
		return "%s %s(%s)" % [type_bbcode, name_string, parameters.to_bbcode()]


class PropertySpecification:
	var name := ""
	var type := "int"
	var default_value := ""
	var explanation := ""

	func _to_string() -> String:
		if default_value != "":
			return "%s %s [default: %s]" % [type, name, default_value]
		return "%s %s" % [type, name]

	func to_bbcode() -> String:
		var type_bbcode := "[color=#%s]%s[/color]" % [COLOR_TYPE.to_html(), type]
		var name_string := "[b][color=#%s]%s[/color][/b]" % [COLOR_MEMBER.to_html(), name]
		if default_value != "":
			var value_string := "[color=#%s][default: %s][/color]" % [COLOR_VALUE.to_html(), default_value]
			return "%s %s %s" % [type_bbcode, name_string, value_string]
		return "%s %s" % [type_bbcode, name_string]

class QueryResult:
	var properties: Array[PropertySpecification] = []
	var methods: Array[MethodSpecification] = []

	func is_empty() -> bool:
		return properties.is_empty() and methods.is_empty()
