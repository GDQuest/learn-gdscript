extends Resource
class_name Documentation

export(String, FILE, "*.csv") var documentation_file := ""
var references := {}


func get_references(names: PoolStringArray) -> Array:
	load_documentation_if_not_loaded()
	var selected_references := []
	for func_name in names:
		if func_name in references:
			var doc_ref := references[func_name] as MethodSpecification
			selected_references.push_back(doc_ref)
	return selected_references


func get_references_as_bbcode(names: PoolStringArray) -> String:
	var selected_references := get_references(names)
	if selected_references.size() == 0:
		return ""
	var as_str = PoolStringArray()
	for method_spec in selected_references:
		method_spec = method_spec as MethodSpecification
		as_str.push_back(method_spec.to_bbcode())
	return as_str.join("\n\n")


func load_documentation_if_not_loaded() -> void:
	assert(documentation_file != "", "documentation file for `%s` not specified"%[resource_path])
	if references.size() == 0:
		references = parse_documentation_file(documentation_file)


static func parse_documentation_file(path: String) -> Dictionary:
	var all_references := {}
	var file := File.new()
	file.open(path, file.READ)
	var _header := Array(file.get_csv_line())
	
	while !file.eof_reached():
		var csv_line := file.get_csv_line()
		var method_spec := MethodSpecification.new()
		method_spec.name = csv_line[0]
		method_spec.return_type = _parse_return_type(csv_line[1])
		method_spec.parameters = _parse_parameters(csv_line[2])
		method_spec.explanation = csv_line[3]
		all_references[method_spec.name] = method_spec
	file.close()
	return all_references


static func _parse_return_type(return_type: String) -> String:
	return_type = return_type.strip_edges()
	return return_type if return_type else "void"  


static func _parse_parameters(parameters_list_string: String) -> MethodList:
	parameters_list_string = parameters_list_string.strip_edges()
	var parameters := MethodList.new()
	if parameters_list_string == "":
		return parameters
	var parameters_list := parameters_list_string.split(",")
	for tuple_str in parameters_list:
		var tuple: PoolStringArray = tuple_str.split(":")
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
			return "%s: %s"%[name, type]
		return "%s: %s = %s"%[name, type, default]

	func to_bbcode() -> String:
		if required:
			return "%s: [i]%s[/i]"%[name, type]
		return "%s: [i]%s[/i] = %s"%[name, type, default]


class MethodList:
	var list := []
	
	func _to_string() -> String:
		return PoolStringArray(list).join(", ")
	
	func to_bbcode() -> String:
		var _list := PoolStringArray()
		for param in list:
			param = param as MethodParameter
			_list.push_back(param.to_bbcode())
		return _list.join(", ")


class MethodSpecification:
	var name := ""
	var return_type := "void"
	var parameters := MethodList.new()
	var explanation := ""
	
	func _to_string() -> String:
		return "%s %s(%s)"%[return_type, name, parameters]

	func to_bbcode() -> String:
		return "[i]%s[/i] %s(%s)\n\n%s"%[return_type, name, parameters.to_bbcode(), explanation]
