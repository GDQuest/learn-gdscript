extends Resource
class_name Documentation

const COLOR_TYPE := Color(0.84511, 0.83905, 0.921875)
const COLOR_MEMBER := Color(0.960784, 0.980392, 0.980392)
const COLOR_PARAMETER := Color(0.84511, 0.83905, 0.921875)
const COLOR_VALUE := Color(0.369263, 0.373399, 0.472656)

@export var documentation_file := "" # (String, FILE, "*.csv")

# Stores instances of MethodSpecification and PropertySpecification.
var _references := {methods = {}, properties = {}}


# Returns the raw reference objects for the requested names.
func get_references(names: PackedStringArray) -> QueryResult:
	# Load CSV docstrings if necessary.
	if _references.methods.is_empty() and _references.properties.is_empty():
		assert(
			documentation_file != "", "documentation file for `%s` not specified" % [resource_path]
		)
		_references = _parse_documentation_file(documentation_file)

	var result := QueryResult.new()
	for name in names:
		if name in _references.methods:
			result.methods.push_back(_references.methods[name])
		elif name in _references.properties:
			result.properties.push_back(_references.properties[name])
	return result


# Returns the reference as formatted BBCode text for the requested names.
func get_references_as_bbcode(names: PackedStringArray) -> String:
	var selected_references := get_references(names)
	if selected_references.is_empty():
		return ""

	var bbcode := ""
	if selected_references.methods:
		bbcode += "[b]Method descriptions[/b]"
		for reference in selected_references.methods:
			bbcode += "\n\n" + reference.to_bbcode()
	if selected_references.properties:
		bbcode += "\n\n" + "[b]Property descriptions[/b]"
		for reference in selected_references.properties:
			bbcode += "\n\n" + reference.to_bbcode()
	return bbcode


static func _parse_documentation_file(path: String) -> Dictionary:
	var all_references := {methods = {}, properties = {}}
	var file := FileAccess.open(path, FileAccess.READ)
	var _header := Array(file.get_csv_line())

	while !file.eof_reached():
		var csv_line := file.get_csv_line()
		if csv_line[0] == "":
			break

		var kind: String = csv_line[4]
		if kind == "method":
			var method_spec := MethodSpecification.new()
			method_spec.name = csv_line[0]
			var return_type: String = csv_line[1].strip_edges()
			method_spec.return_type = return_type if return_type else "void"
			method_spec.parameters = _parse_parameters(csv_line[2])
			method_spec.explanation = csv_line[3].strip_edges()
			all_references.methods[method_spec.name] = method_spec
		elif kind == "property":
			var property_spec := PropertySpecification.new()
			property_spec.name = csv_line[0]
			var type: String = csv_line[1].strip_edges()
			property_spec.type = type if type else "void"
			property_spec.explanation = csv_line[3]
			property_spec.default_value = csv_line[5]
			all_references.properties[property_spec.name] = property_spec
		else:
			printerr("Unknown kind for line %s: %s" % [csv_line, kind])

	file.close()
	return all_references


static func _parse_parameters(parameters_list_string: String) -> MethodParameterList:
	parameters_list_string = parameters_list_string.strip_edges()
	var parameters := MethodParameterList.new()
	if parameters_list_string == "":
		return parameters

	var parameters_list := parameters_list_string.split(",")
	for tuple_str in parameters_list:
		var tuple: PackedStringArray = tuple_str.split(":")
		var param := MethodParameter.new()
		param.name = tuple[0].strip_edges()
		if tuple.size() > 1:
			var type := tuple[1].strip_edges().split("=")
			param.type = type[0].strip_edges()
			if type.size() > 1:
				param.default = type[1].strip_edges()
				param.required = false
		parameters.list.push_back(param)
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
		var type_string := "[color=#%s]%s[/color]" % [COLOR_TYPE.to_html(), type]
		var value_string := "[b][color=#%s]%s[/color][/b]" % [COLOR_VALUE.to_html(), default]

		if required:
			return "%s: %s" % [name_string, type_string]
		return "%s: %s = %s" % [name_string, type_string, value_string]


class MethodParameterList:
	var list := []

	func _to_string() -> String:
		return ", ".join(PackedStringArray(list))

	func to_bbcode() -> String:
		var _list := PackedStringArray()
		for param in list:
			param = param as MethodParameter
			_list.push_back(param.to_bbcode())
		return ", ".join(_list)


class MethodSpecification:
	var name := ""
	var return_type := "void"
	var parameters := MethodParameterList.new()
	var explanation := ""

	func _to_string() -> String:
		return "%s %s(%s)" % [return_type, name, parameters]

	func to_bbcode() -> String:
		var type_string := "[color=#%s]%s[/color]" % [COLOR_TYPE.to_html(), return_type]
		var name_string := "[b][color=#%s]%s[/color][/b]" % [COLOR_MEMBER.to_html(), name]

		return "%s %s(%s)" % [type_string, name_string, parameters.to_bbcode()]


class PropertySpecification:
	var name := ""
	var type := "int"
	var default_value := ""
	var explanation := ""

	func _to_string() -> String:
		if default_value:
			return "%s %s [default: %s]" % [type, name, default_value]
		return "%s %s" % [type, name]

	func to_bbcode() -> String:
		var type_string := "[color=#%s]%s[/color]" % [COLOR_TYPE.to_html(), type]
		var name_string := "[b][color=#%s]%s[/color][/b]" % [COLOR_MEMBER.to_html(), name]
		if default_value:
			var value_string := (
				"[color=#%s][default: %s][/color]"
				% [COLOR_VALUE.to_html(), default_value]
			)
			return "%s %s %s" % [type_string, name_string, value_string]
		return "%s %s" % [type_string, name_string]


class QueryResult:
	var properties := []
	var methods := []

	func is_empty() -> bool:
		return properties.is_empty() and methods.is_empty()
