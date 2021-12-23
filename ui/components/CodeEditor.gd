tool
class_name CodeEditor
extends PanelContainer

signal text_changed(text)
signal action(action)
signal console_toggled

const ACTIONS := {
	"RUN": "run", "PAUSE": "pause", "SOLUTION": "solution", "RESTORE": "restore", "DFMODE": "dfmode"
}

const EDITOR_EXPAND_ICON := preload("res://ui/icons/expand.png")
const EDITOR_COLLAPSE_ICON := preload("res://ui/icons/collapse.png")

export (String, MULTILINE) var text := "" setget set_text, get_text

var _initial_text := ""

onready var slice_editor := find_node("SliceEditor") as SliceEditor

onready var _run_button := find_node("RunButton") as Button
onready var _pause_button := find_node("PauseButton") as Button
onready var _solution_button := find_node("SolutionButton") as Button
onready var _restore_button := find_node("RestoreButton") as Button
onready var _console_button := find_node("ConsoleButton") as Button
onready var _df_mode_button := find_node("DFMButton") as Button


func _ready() -> void:
	_df_mode_button.icon = EDITOR_EXPAND_ICON
	
	_restore_button.connect("pressed", self, "_on_restore_pressed")
	_restore_button.disabled = true
	_solution_button.connect("pressed", self, "_on_solution_pressed")

	_run_button.connect("pressed", self, "emit_signal", ["action", ACTIONS.RUN])
	_pause_button.connect("pressed", self, "emit_signal", ["action", ACTIONS.PAUSE])
	_solution_button.connect("pressed", self, "emit_signal", ["action", ACTIONS.SOLUTION])
	_restore_button.connect("pressed", self, "emit_signal", ["action", ACTIONS.RESTORE])
	_df_mode_button.connect("pressed", self, "emit_signal", ["action", ACTIONS.DFMODE])
	_console_button.connect("pressed", self, "emit_signal", ["console_toggled"])

	slice_editor.connect("text_changed", self, "_on_text_changed")
	yield(get_tree(), "idle_frame")
	_initial_text = text


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


func set_distraction_free_state(enabled: bool) -> void:
	if enabled:
		_df_mode_button.icon = EDITOR_COLLAPSE_ICON
	else:
		_df_mode_button.icon = EDITOR_EXPAND_ICON
