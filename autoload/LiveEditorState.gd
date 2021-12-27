extends Node

var current_slice: SliceProperties
var error_database: GDScriptErrorDatabase


func _init() -> void:
	error_database = GDScriptErrorDatabase.new()
