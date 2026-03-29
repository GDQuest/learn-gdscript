# Displays a scene inside a frame.
class_name GameView
extends Control

@export var _viewport_container: SubViewportContainer
@export var _pause_rect: ColorRect

var paused := false:
	set = set_paused

var _viewport := SubViewport.new()

@onready var _scene_tree := get_tree()


func _ready() -> void:
	_pause_rect.visible = false
	_viewport.name = "SubViewport"
	_viewport_container.add_child(_viewport)
	get_viewport().size_changed.connect(_on_screen_resized)
	_on_screen_resized.call_deferred()


func toggle_paused() -> void:
	set_paused(not paused)


func set_paused(value: bool) -> void:
	paused = value
	_scene_tree.paused = paused
	_pause_rect.visible = paused


func use_scene(node: Node, viewport_size: Vector2) -> void:
	_viewport.add_child(node)
	move_child(_pause_rect, -1)
	_viewport.size = viewport_size


func get_viewport_override() -> SubViewport:
	return _viewport


func _on_screen_resized() -> void:
	_viewport.size = size
