class_name CodeExampleVariableUnderline
extends Node2D

const LINE_COLOR := Color(1, 0.96, 0.25)
const LINE_WIDTH := 3.0
const TWEEN_DURATION := 0.2

# Godot 4: Resources should be specifically typed if possible
@export var font_resource: Font

# Godot 4: setget replaced with colon property syntax
var highlight_rect := Rect2(): 
	set = set_highlight_rect
	
var variable_name := ""

var highlight_line := -1
var highlight_column := -1

# RefCounted is the base for Objects that are not Nodes, like the setup expects
@onready var _scene_instance: Node
@onready var _mouse_blocker := $MouseBlocker as Control
@onready var _label := $MouseBlocker/Label as Label


func _ready() -> void:
	# Godot 4: Signal connection syntax
	_mouse_blocker.mouse_entered.connect(_on_blocker_mouse_entered)
	_mouse_blocker.mouse_exited.connect(_on_blocker_mouse_exited)


func setup(runnable_code: Node, scene_instance: Node) -> void:
	# Godot 4: Connect to custom signal
	runnable_code.connect("code_updated", _update_label_text)
	_scene_instance = scene_instance


func set_highlight_rect(value: Rect2) -> void:
	highlight_rect = value

	if not is_node_ready():
		await ready

	# Godot 4: rect_position/rect_size -> position/size
	_mouse_blocker.position = highlight_rect.position
	_mouse_blocker.size = highlight_rect.size


func _update_label_text() -> void:
	if not _scene_instance:
		return
		
	_label.text = str(_scene_instance.get(variable_name))
	
	# Godot 4: Accessing fonts and sizes from theme overrides
	# Font.get_string_size now requires the font_size as an argument
	var font := _label.get_theme_font("font")
	var font_size := _label.get_theme_font_size("font_size")
	
	var string_size := font.get_string_size(
		_label.text, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		-1, 
		font_size
	)
	
	_label.size = string_size
	
	# Center the label relative to the blocker
	_label.position.x = (_mouse_blocker.size.x / 2.0 - _label.size.x / 2.0)


func _on_blocker_mouse_entered() -> void:
	_update_label_text()
	_label.show()


func _on_blocker_mouse_exited() -> void:
	_label.hide()
