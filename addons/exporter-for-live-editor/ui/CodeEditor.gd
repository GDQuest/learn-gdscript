tool
class_name CodeEditor
extends PanelContainer

const SliceEditor := preload("../ui/SliceEditor.gd")

onready var slice_editor := find_node("SliceEditor") as SliceEditor
onready var save_button := find_node("SaveButton") as Button
onready var pause_button := find_node("PauseButton") as Button
onready var solution_button := find_node("SolutionButton") as Button
onready var view_mode_toggle := find_node("ViewModeToggleButton") as ViewModeToggleButton

export var split_container_path: NodePath setget set_split_container_path

signal text_changed(text)


func _ready() -> void:
	slice_editor.connect("text_changed", self, "_on_text_changed")


func set_split_container_path(path: NodePath) -> void:
	split_container_path = path
	if not is_inside_tree():
		yield(self, "ready")
	var node = get_node_or_null(path)
	if not (node is SplitContainer):
		push_error("nodepath %s does not yield a SplitContainer" % [path])
		return
	view_mode_toggle.split_container = node


func _on_text_changed(text: String) -> void:
	emit_signal("text_changed", text)
