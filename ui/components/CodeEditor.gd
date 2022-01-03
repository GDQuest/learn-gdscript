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

export(String, MULTILINE) var text := "" setget set_text, get_text

var _initial_text := ""

# When pressing the run button, we disable buttons until the server responds.
# When the server responds, we use this var to restore the buttons' previous
# disabled state.
var _buttons_previous_disabled_state := {}

onready var slice_editor := $Column/PanelContainer/SliceEditor as SliceEditor

onready var _run_button := $Column/MarginContainer/Column/Row/RunButton as Button
onready var _pause_button := $Column/MarginContainer/Column/Row/PauseButton as Button
onready var _solution_button := $Column/MarginContainer/Column/Row2/SolutionButton as Button
onready var _restore_button := $Column/MarginContainer/Column/Row2/RestoreButton as Button
onready var _console_button := $Column/MarginContainer/Column/Row/ConsoleButton as Button
onready var _distraction_free_mode_button := $Column/PanelContainer/DFMButton as Button

# Buttons to toggle disabled when running the code, until the server responds.
onready var _buttons_to_disable := [_run_button, _pause_button, _solution_button, _restore_button]
# We generate a shortcut tooltip for each of those buttons.
onready var _buttons_with_shortcuts := [
	_run_button,
	_restore_button,
	_solution_button,
	_console_button,
	_pause_button,
	_distraction_free_mode_button
]


func _ready() -> void:
	_distraction_free_mode_button.icon = EDITOR_EXPAND_ICON

	_restore_button.connect("pressed", self, "_on_restore_pressed")
	_restore_button.disabled = true
	_solution_button.connect("pressed", self, "_on_solution_pressed")

	_run_button.connect("pressed", self, "emit_signal", ["action", ACTIONS.RUN])
	_run_button.connect("pressed", self, "_on_run_button_pressed")
	_pause_button.connect("pressed", self, "emit_signal", ["action", ACTIONS.PAUSE])
	_solution_button.connect("pressed", self, "emit_signal", ["action", ACTIONS.SOLUTION])
	_restore_button.connect("pressed", self, "emit_signal", ["action", ACTIONS.RESTORE])
	_distraction_free_mode_button.connect(
		"pressed", self, "emit_signal", ["action", ACTIONS.DFMODE]
	)
	_console_button.connect("pressed", self, "emit_signal", ["console_toggled"])

	slice_editor.connect("text_changed", self, "_on_text_changed")
	yield(get_tree(), "idle_frame")
	_initial_text = text

	for button in _buttons_with_shortcuts:
		assert(
			button.shortcut.shortcut is InputEventAction,
			"Buttons must use an action as a shortcut to generate a shortcut tooltip for them."
		)
		var action_name: String = button.shortcut.shortcut.action
		button.hint_tooltip += "\n" + TextUtils.convert_input_action_to_tooltip(action_name)


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


func set_pause_button_pressed(is_pressed: bool) -> void:
	_pause_button.pressed = is_pressed


# Restores the disabled state of the disabled buttons.
func enable_buttons() -> void:
	for button in _buttons_previous_disabled_state:
		button.disabled = _buttons_previous_disabled_state[button]
	_run_button.disabled = false


func _on_text_changed() -> void:
	_restore_button.disabled = false
	emit_signal("text_changed", slice_editor.text)


func _on_restore_pressed() -> void:
	_restore_button.disabled = true
	set_text(_initial_text)


func _on_solution_pressed() -> void:
	_restore_button.disabled = false
	slice_editor.sync_text_with_slice()


func _on_run_button_pressed() -> void:
	for button in _buttons_to_disable:
		_buttons_previous_disabled_state[button] = button.disabled
		button.disabled = true
	emit_signal("action", ACTIONS.RUN)
