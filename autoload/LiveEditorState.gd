extends Node

signal slice_changed

var current_slice: SliceProperties
var current_scene: Node

var error_database: GDScriptErrorDatabase


func _init() -> void:
	error_database = GDScriptErrorDatabase.new()


func use_scene(parent: Node) -> void:
	var previous_parent := current_scene.get_parent()
	if previous_parent != null:
		current_scene.get_parent().remove_child(current_scene)

	var is_canvas_item := current_scene is CanvasItem
	var starting_visibility := (current_scene as CanvasItem).visible if is_canvas_item else false
	
	parent.add_child(current_scene)
	
	if is_canvas_item:
		(current_scene as CanvasItem).visible = starting_visibility
	
	parent.connect("tree_exited", self, "_on_scene_parent_removed")


func _on_scene_parent_removed() -> void:
	if current_scene and current_scene.get_parent():
		current_scene.get_parent().remove_child(current_scene)

