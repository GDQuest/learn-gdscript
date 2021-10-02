tool
extends HBoxContainer

const GAME = "game"
const CONSOLE = "console"
const BOTH = "both"

signal mode_changed(new_mode, from_user)

export(String, "game", "console", "both") var view_mode := "both" setget set_view_mode

var _do_send_signals := true


func _ready():
	var group := ButtonGroup.new()
	for child in get_children():
		if child is BaseButton:
			child.toggle_mode = true
			child.group = group
			child.connect("toggled", self, "_on_button_toggled", [child.name])


func set_view_mode(new_mode: String) -> void:
	assert(new_mode in [GAME, CONSOLE, BOTH])
	view_mode = new_mode
	_do_send_signals = false
	get_node(view_mode).pressed = true
	emit_signal("mode_changed", view_mode, false)
	_do_send_signals = true


func _on_button_toggled(is_toggled: bool, new_mode: String):
	if is_toggled:
		view_mode = new_mode
		if _do_send_signals:
			emit_signal("mode_changed", view_mode, true)
