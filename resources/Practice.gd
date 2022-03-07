# Holds the data for one practice
class_name Practice
extends Resource

const QueryResult := Documentation.QueryResult

# Uniquely identifies the practice resource.
export var practice_id := ""

export var title := ""
export(String, MULTILINE) var goal := ""
export(String, MULTILINE) var starting_code := ""
export(int, 9999) var cursor_line := 0
export(int, 9999) var cursor_column := 0
export var hints := PoolStringArray()
export(String, FILE) var validator_script_path := ""
export(String, FILE) var script_slice_path := ""
export var documentation_references := PoolStringArray()
export var documentation_resource: Resource = preload("res://course/Documentation.tres") setget set_documentation_resource
export var description := ""


func set_documentation_resource(new_documentation_resource: Resource) -> void:
	assert(
		(new_documentation_resource == null) or (new_documentation_resource is Documentation),
		"resource `%s` is not a Documentation resource" % [new_documentation_resource.resource_path]
	)
	documentation_resource = new_documentation_resource


func get_documentation_resource() -> Documentation:
	return documentation_resource as Documentation


func get_documentation_raw() -> QueryResult:
	if documentation_resource == null:
		if not documentation_references.empty():
			push_error(
				"Documentation References were selected, but no documentation resource was set"
			)
		return null
	return get_documentation_resource().get_references(documentation_references)
