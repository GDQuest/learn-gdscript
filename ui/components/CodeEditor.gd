tool
class_name CodeEditor
extends PanelContainer

signal text_changed(text)
signal action(action)

const ACTIONS := {"RUN": "run", "PAUSE": "pause", "SOLUTION": "solution", "RESTORE": "restore"}

export var split_container_path: NodePath setget set_split_container_path
export (String, MULTILINE) var text := "" setget set_text, get_text

var _initial_text := ""

var _split_container: SplitContainer = null

onready var slice_editor := find_node("SliceEditor") as SliceEditor
onready var _run_button := find_node("RunButton") as Button
onready var _pause_button := find_node("PauseButton") as Button
onready var _solution_button := find_node("SolutionButton") as Button
onready var _restore_button := find_node("RestoreButton") as Button
onready var _view_mode_toggle := find_node("ViewModeToggleButton") as ViewModeToggleButton


func _ready() -> void:
	assert(_view_mode_toggle)
	_restore_button.connect("pressed", self, "_on_restore_pressed")
	_restore_button.disabled = true
	_solution_button.connect("pressed", self, "_on_solution_pressed")

	_run_button.connect("pressed", self, "emit_signal", ["action", ACTIONS.RUN])
	_pause_button.connect("pressed", self, "emit_signal", ["action", ACTIONS.PAUSE])
	_solution_button.connect("pressed", self, "emit_signal", ["action", ACTIONS.SOLUTION])
	_restore_button.connect("pressed", self, "emit_signal", ["action", ACTIONS.RESTORE])

	slice_editor.connect("text_changed", self, "_on_text_changed")
	yield(get_tree(), "idle_frame")
	_initial_text = text


func _get_configuration_warning() -> String:
	if not split_container_path or not get_node(split_container_path) is SplitContainer:
		return (
			"The Split Container Path property should point to a SplitContainer node.\n"
			+ "The game and console toggle buttons won't work."
		)
	return ""


func _on_text_changed() -> void:
	_restore_button.disabled = false
	emit_signal("text_changed", slice_editor.text)


func _on_restore_pressed() -> void:
	_restore_button.disabled = true
	set_text(_initial_text)


func _on_solution_pressed() -> void:
	_restore_button.disabled = false
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


func set_split_container_path(value: NodePath) -> void:
	if value == split_container_path:
		return
	split_container_path = value
	if not is_inside_tree():
		yield(self, "ready")

	_split_container = get_node(split_container_path)
	if not _split_container:
		printerr("Path %s should point to a SplitContainer node." % split_container_path)
		return

	_view_mode_toggle.connect("game_button_toggled", _split_container, "toggle_game_view")
	_view_mode_toggle.connect("console_button_toggled", _split_container, "toggle_console_view")
