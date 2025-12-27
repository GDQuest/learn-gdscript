# Displays a scene inside a frame.
class_name GameView
extends Control

var _paused: bool = false

var paused: bool:
	set(value):
		set_paused(value)
	get:
		return _paused
		
var _viewport: SubViewport = SubViewport.new()

@onready var _viewport_container := $ViewportContainer as SubViewportContainer
@onready var _pause_rect := $PauseRect as ColorRect
var _scene_tree: SceneTree


func _ready() -> void:
	_pause_rect.visible = false
	_viewport.name = "Viewport"
	_viewport_container.add_child(_viewport)
	_scene_tree = get_tree()
	get_viewport().size_changed.connect(_on_screen_resized)
	call_deferred("_on_screen_resized")


func toggle_paused() -> void:
	set_paused(not paused)


func set_paused(value: bool) -> void:
	_paused = value
	_scene_tree.paused = _paused
	_pause_rect.visible = _paused



func use_scene(node: Node, viewport_size: Vector2) -> void:
	_viewport.add_child(node)
	_pause_rect.move_to_front()
	_viewport.size = viewport_size


func get_game_viewport() -> SubViewport:
	return _viewport


func _on_screen_resized() -> void:
	_viewport.size = size
