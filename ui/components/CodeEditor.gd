tool
class_name CodeEditor
extends PanelContainer

signal text_changed(text)
signal action_taken(action)
signal console_toggled

const ACTIONS := {
	"RUN": "run",
	"PAUSE": "pause",
	"SOLUTION": "solution",
	"RESTORE": "restore",
	"CONTINUE": "continue",
	"DFMODE": "dfmode",
}

const EDITOR_EXPAND_ICON := preload("res://ui/icons/expand.png")
const EDITOR_COLLAPSE_ICON := preload("res://ui/icons/collapse.png")

export(String, MULTILINE) var text := "" setget set_text, get_text

var _initial_text := ""

# When pressing the run button, we disable buttons until the checks complete.
# Once done, we use this var to restore the buttons' previous disabled state.
var _buttons_previous_disabled_state := {}

onready var slice_editor := $Column/PanelContainer/SliceEditor as SliceEditor

onready var _run_button := $Column/MarginContainer/Column/Row/RunButton as Button
onready var _pause_button := $Column/MarginContainer/Column/Row/PauseButton as Button
onready var _restore_button := $Column/MarginContainer/Column/Row/RestoreButton as Button
onready var _solution_button := $Column/MarginContainer/Column/Row2/SolutionButton as Button
onready var _console_button := $Column/MarginContainer/Column/Row2/ConsoleButton as Button
onready var _continue_button := $Column/MarginContainer/Column/Row2/ContinueButton as Button

onready var _distraction_free_mode_button := $Column/PanelContainer/DFMButton as Button

onready var _locked_overlay := $Column/PanelContainer/LockedOverlay as Control
onready var _locked_overlay_label := $Column/PanelContainer/LockedOverlay/Layout/Label as Label


# Buttons to toggle disabled when running the code, until the server responds.
onready var _buttons_to_disable := [
	_run_button,
	_pause_button,
	_solution_button,
	_restore_button,
	_continue_button,
]
# We generate a shortcut tooltip for each of those buttons.
onready var _buttons_with_shortcuts := [
	_run_button,
	_restore_button,
	_solution_button,
	_console_button,
	_pause_button,
	_distraction_free_mode_button,
]


func _ready() -> void:
	_distraction_free_mode_button.icon = EDITOR_EXPAND_ICON
	_locked_overlay.hide()

	_restore_button.disabled = true
	_restore_button.connect("pressed", self, "_on_restore_button_pressed")
	_run_button.connect("pressed", self, "_on_run_button_pressed")
	_pause_button.connect("pressed", self, "emit_signal", ["action_taken", ACTIONS.PAUSE])
	_solution_button.connect("pressed", self, "emit_signal", ["action_taken", ACTIONS.SOLUTION])
	_continue_button.connect("pressed", self, "emit_signal", ["action_taken", ACTIONS.CONTINUE])
	_distraction_free_mode_button.connect(
		"pressed", self, "emit_signal", ["action_taken", ACTIONS.DFMODE]
	)
	_console_button.connect("pressed", self, "emit_signal", ["console_toggled"])

	slice_editor.connect("text_changed", self, "_on_text_changed")
	slice_editor.connect("gui_input", self, "_gui_input")
	yield(get_tree(), "idle_frame")
	_initial_text = text

	slice_editor.grab_focus()

	if not Engine.editor_hint:
		for button in _buttons_with_shortcuts:
			assert(
				button.shortcut.shortcut is InputEventAction,
				"Buttons must use an action as a shortcut to generate a shortcut tooltip for them."
			)
			var action_name: String = button.shortcut.shortcut.action
			button.hint_tooltip += "\n" + TextUtils.convert_input_action_to_tooltip(action_name)


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("run_code") and not _run_button.disabled:
		_on_run_button_pressed()
		accept_event()


func update_cursor_position(line: int, column: int) -> void:
	# Fix for lines with TAB indent
	column = column - 1
	line = line - 1
	var string = slice_editor.get_line(line)
	var tabs = min(column, string.count("\t"))
	column = 3 * tabs + column

	slice_editor.cursor_set_line(1000000 if line < 0 else line)
	slice_editor.cursor_set_column(1000000 if column < 0 else column)


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
		_distraction_free_mode_button.icon = EDITOR_COLLAPSE_ICON
	else:
		_distraction_free_mode_button.icon = EDITOR_EXPAND_ICON


func is_pause_button_pressed() -> bool:
	return _pause_button.pressed


func set_pause_button_pressed(is_pressed: bool) -> void:
	_pause_button.pressed = is_pressed


func is_solution_button_pressed() -> bool:
	return _solution_button.pressed


func set_solution_button_pressed(is_pressed: bool) -> void:
	_solution_button.pressed = is_pressed


func set_restore_allowed(allowed: bool) -> void:
	_restore_button.disabled = not allowed


func set_continue_allowed(allowed: bool) -> void:
	_continue_button.disabled = not allowed


func lock_editor() -> void:
	for button in _buttons_to_disable:
		_buttons_previous_disabled_state[button] = button.disabled
		button.disabled = true
	
	_locked_overlay.show()


# Restores the disabled state of the disabled buttons.
func unlock_editor() -> void:
	for button in _buttons_previous_disabled_state:
		button.disabled = _buttons_previous_disabled_state[button]
	_run_button.disabled = false
	
	_locked_overlay.hide()
	set_locked_message("")


func set_locked_message(message: String) -> void:
	_locked_overlay_label.text = message


func _on_text_changed() -> void:
	_restore_button.disabled = false
	emit_signal("text_changed", slice_editor.text)


func _on_restore_button_pressed() -> void:
	set_text(_initial_text)
	unlock_editor()
	emit_signal("action_taken", ACTIONS.RESTORE)
	_restore_button.disabled = true


func _on_run_button_pressed() -> void:
	emit_signal("action_taken", ACTIONS.RUN)
