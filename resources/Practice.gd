# Holds the data for one practice
class_name Practice
extends Resource

const QueryResult := Documentation.QueryResult

@export var practice_id := ""
@export var title := ""
@export var goal := ""
@export var starting_code := ""
@export var cursor_line := 0
@export var cursor_column := 0
@export var hints: PackedStringArray = PackedStringArray()
@export var validator_script_path := ""
@export var script_slice_path := ""
@export var slice_name := ""
@export var documentation_references: PackedStringArray = PackedStringArray()
@export var description := ""

var _documentation_resource: Resource = preload("res://course/Documentation.tres")

@export var documentation_resource: Resource:
	get:
		return _documentation_resource
	set(value):
		set_documentation_resource(value)


func set_documentation_resource(new_documentation_resource: Resource) -> void:
	assert(
		(new_documentation_resource == null) or (new_documentation_resource is Documentation),
		"resource `%s` is not a Documentation resource" % [new_documentation_resource.resource_path]
	)
	_documentation_resource = new_documentation_resource


func get_documentation_resource() -> Documentation:
	return _documentation_resource as Documentation


func get_documentation_raw() -> Documentation.QueryResult:
	if _documentation_resource == null:
		if not documentation_references.is_empty():
			push_error("Documentation References were selected, but no documentation resource was set")
		return null
	return get_documentation_resource().get_references(documentation_references)
