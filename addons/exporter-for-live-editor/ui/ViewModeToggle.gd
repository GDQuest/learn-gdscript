tool
extends "./ButtonsContainer.gd"

const BOTH = "both"
const GAME = "game"
const CONSOLE = "console"

export(String, "both", "game", "console") var mode := BOTH setget set_mode, get_mode

func _init() -> void:
	values = [ BOTH, GAME, CONSOLE ]
	for button_name in values:
		var button := Button.new()
		button.text = button_name
		button.toggle_mode = true
		button.set_meta("value", button_name)
		add_child(button)

func _ready() -> void:
	select_first()


func set_mode(new_mode: String) -> void:
	if new_mode != BOTH and new_mode != GAME and new_mode != CONSOLE:
		return
	mode = new_mode
	set_selected_value(new_mode)


func get_mode() -> String:
	var _mode = get_selected_value()
	if _mode == GAME:
		return GAME
	elif _mode == CONSOLE:
		return CONSOLE
	return BOTH
