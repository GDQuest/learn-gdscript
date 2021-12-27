# Holds a scene, and offers some utilities to play it, pause it, and replace
# scripts on running nodes.
class_name GameViewport
extends ViewportContainer

var _viewport := Viewport.new()

onready var _scene_tree := get_tree()


func _init() -> void:
	_viewport.name = "Viewport"
	add_child(_viewport)


func _ready() -> void:
	_scene_tree.connect("screen_resized", self, "_on_screen_resized")
	_scene_tree.call_deferred("emit_signal", "screen_resized")


# Toggles a scene's paused state on and off
func toggle_scene_pause() -> void:
	_scene_tree.paused = not _scene_tree.paused


func use_scene(node: Node, viewport_size: Vector2) -> void:
	_viewport.add_child(node)
	_viewport.size = viewport_size


func get_viewport() -> Viewport:
	return _viewport


func _on_screen_resized() -> void:
	_viewport.size = rect_size
