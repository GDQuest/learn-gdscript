tool
class_name CodeEditor
extends PanelContainer

const SliceEditor := preload("../ui/SliceEditor.gd")

onready var slice_editor := find_node("SliceEditor") as SliceEditor
onready var save_button := find_node("SaveButton") as Button
onready var pause_button := find_node("PauseButton") as Button
onready var solution_button := find_node("SolutionButton") as Button
onready var restore_button := find_node("RestoreButton") as Button
onready var view_mode_toggle := find_node("ViewModeToggleButton") as ViewModeToggleButton

var _initial_text := ""

export var split_container_path: NodePath setget set_split_container_path
export (String, MULTILINE) var text := "" setget set_text, get_text

signal text_changed(text)


func _ready() -> void:
	restore_button.connect("pressed", self, "_on_restore_pressed")
	restore_button.disabled = true
	solution_button.connect("pressed", self, "_on_solution_pressed")
	slice_editor.connect("text_changed", self, "_on_text_changed")
	yield(get_tree(), "idle_frame")
	_initial_text = text


func set_split_container_path(path: NodePath) -> void:
	if Engine.editor_hint:
		return
	split_container_path = path
	if not is_inside_tree():
		yield(self, "ready")
	var node = get_node_or_null(path)
	if not (node is SplitContainer):
		push_error("nodepath %s does not yield a SplitContainer" % [path])
		return
	view_mode_toggle.split_container = node


func _on_text_changed() -> void:
	restore_button.disabled = false
	emit_signal("text_changed", slice_editor.text)


func _on_restore_pressed() -> void:
	restore_button.disabled = true
	set_text(_initial_text)


func _on_solution_pressed() -> void:
	restore_button.disabled = false
	slice_editor.sync_text_with_slice()


func set_text(new_text: String) -> void:
	text = new_text
	if not is_inside_tree():
		yield(self, "ready")
	slice_editor.text = new_text


func get_text() -> String:
	if not is_inside_tree():
		return text
	return slice_editor.text
