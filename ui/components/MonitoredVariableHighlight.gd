class_name MonitoredVariableHighlight
extends Node2D

const LINE_COLOR := Color(1, 0.96, 0.25)
const LINE_WIDTH := 3.0
const TWEEN_DURATION := 0.2

export(Resource) var font_resource

onready var highlight_rect : Rect2 setget set_highlight_rect
onready var variable_name : String

onready var _scene_instance : Node
onready var _mouse_inside := false
onready var _mouse_blocker := $MouseBlocker as Control
onready var _variable_value : String


func _ready() -> void:
	_mouse_blocker.connect("mouse_entered", self, "_on_blocker_mouse_entered")
	_mouse_blocker.connect("mouse_exited", self, "_on_blocker_mouse_exited")


func _draw() -> void:
	if _mouse_inside:
		draw_string(font_resource, highlight_rect.position + (Vector2.RIGHT * 3) + (Vector2.UP * 3), _variable_value, Color.white)


func setup(runnable_code, scene_instance : Node) -> void:
	runnable_code.connect("code_updated", self, "_on_code_updated")
	_scene_instance = scene_instance


func set_highlight_rect(value) -> void:
	highlight_rect = value

	if not is_inside_tree():
		yield(self, "ready")

	_mouse_blocker.rect_position = highlight_rect.position
	_mouse_blocker.rect_size = highlight_rect.size

	update()


func _on_code_updated():
	_variable_value = str(_scene_instance.get(variable_name))
	update()


func _on_blocker_mouse_entered():
	_mouse_inside = true
	update()


func _on_blocker_mouse_exited():
	_mouse_inside = false
	update()

